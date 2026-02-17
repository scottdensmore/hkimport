//
//  HKimporter.swift
//  HealthKitImporter
//
//  Created by boaz saragossi on 11/7/17.
//  Copyright © 2017 boaz saragossi. All rights reserved.
//

import Foundation
import HealthKit
import os.log

extension CustomStringConvertible {
    var description: String {
        var description: String = "\(type(of: self))\n"
        let selfMirror = Mirror(reflecting: self)
        for child in selfMirror.children {
            if let propertyName = child.label {
                description += "\(propertyName): \(child.value)\n"
            }
        }
        return description
    }
}

class HealthRecord: CustomStringConvertible {
    var type: String = String()
    var value: Double = 0
    var unit: String?
    var sourceName: String = String()
    var sourceVersion: String = String()
    var startDate: Date = Date()
    var endDate: Date = Date()
    var creationDate: Date = Date()

    // Workout data
    var activityType: HKWorkoutActivityType? = HKWorkoutActivityType(rawValue: 0)
    var totalEnergyBurned: Double = 0
    var totalDistance: Double = 0
    var totalEnergyBurnedUnit: String = String()
    var totalDistanceUnit: String = String()

    var metadata: [String: Any]?
}

class Importer: NSObject, XMLParserDelegate {
    var healthStore: HKHealthStore?

    var cutDate: Date?
    var allSamples: [HKSample] = []
    var workoutRecords: [HealthRecord] = []
    var authorizedTypes: [HKSampleType: Bool] = [:]
    var readCount = 0
    var writeCount = 0
    var currentRecord: HealthRecord = HealthRecord.init()
    var onReadCountUpdated: ((Int) -> Void)?
    var onWriteCountUpdated: ((Int) -> Void)?
    var numberFormatter: NumberFormatter?
    var dateFormatter: DateFormatter?

    convenience init(completion: @escaping () -> Void, failure: ((String) -> Void)? = nil) {
        self.init()

        self.healthStore = HKHealthStore.init()
        self.healthStore?.requestAuthorization(toShare: Constants.allSampleTypes, read: Constants.allSampleTypes, completion: { success, error in
            if let error = error, Constants.loggingEnabled {
                os_log("Error: %@", error.localizedDescription)
            }

            if success {
                completion()
            } else {
                failure?(error?.localizedDescription ?? "Health access was not granted.")
            }
        })

        self.numberFormatter = NumberFormatter.init()
        numberFormatter?.locale = Locale.current
        numberFormatter?.numberStyle = .decimal

        self.dateFormatter = DateFormatter()
        dateFormatter?.dateFormat = "yyyy-MM-dd HH:mm:ss Z"

        // Uncomment if you only want to import the last 1 month
        // If your export.xml is large, you likely need to enable this as
        // otherwise the saveSamples method will fail
        // self.cutDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        if elementName == "Record" {
            parseRecordFromAttributes(attributeDict)
        } else if elementName == "MetadataEntry" {
            parseMetaDataFromAttributes(attributeDict)
        } else if elementName == "Workout" {
            parseWorkoutFromAttributes(attributeDict)
        } else {
            return
        }
    }

    fileprivate func parseRecordFromAttributes(_ attributeDict: [String: String]) {
        currentRecord.type = attributeDict["type"]!
        currentRecord.sourceName = attributeDict["sourceName"] ??  ""
        currentRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
        currentRecord.value = Double(attributeDict["value"] ?? "0") ?? 0
        currentRecord.unit = attributeDict["unit"] ?? ""
        if let date = dateFormatter?.date(from: attributeDict["startDate"]!) {
            currentRecord.startDate = date
        }
        if let date = dateFormatter?.date(from: attributeDict["endDate"]!) {
            currentRecord.endDate = date
        }
        if currentRecord.startDate >  currentRecord.endDate {
            currentRecord.startDate = currentRecord.endDate
        }
        if let date = dateFormatter?.date(from: attributeDict["creationDate"]!) {
            currentRecord.creationDate = date
        }
    }

    fileprivate func parseMetaDataFromAttributes(_ attributeDict: [String: String]) {
        guard let key = attributeDict["key"],
              let rawValue = attributeDict["value"] else {
            return
        }
        if key == HKMetadataKeySyncIdentifier || key == HKMetadataKeySyncVersion {
            return
        }

        let parsedValue: Any
        if rawValue.hasSuffix("%") {
            let trimmedPercent = rawValue.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let percent = numberFormatter?.number(from: trimmedPercent)?.doubleValue {
                parsedValue = HKQuantity(unit: .percent(), doubleValue: percent)
            } else {
                parsedValue = rawValue
            }
        } else if key.uppercased().contains("UUID") {
            parsedValue = rawValue
        } else if let intValue = Int(rawValue) {
            parsedValue = intValue
        } else {
            parsedValue = rawValue
        }

        if currentRecord.metadata == nil {
            currentRecord.metadata = [:]
        }
        currentRecord.metadata?[key] = parsedValue
    }

    fileprivate func parseWorkoutFromAttributes(_ attributeDict: [String: String]) {
        currentRecord.type = HKObjectType.workoutType().identifier
        currentRecord.activityType = HKWorkoutActivityType.activityTypeFromString(attributeDict["workoutActivityType"] ?? "")
        currentRecord.sourceName = attributeDict["sourceName"] ??  ""
        currentRecord.sourceVersion = attributeDict["sourceVersion"] ??  ""
        currentRecord.value = Double(attributeDict["duration"] ?? "0") ?? 0
        currentRecord.unit = attributeDict["durationUnit"] ?? ""
        currentRecord.totalDistance = Double(attributeDict["totalDistance"] ?? "0") ?? 0
        currentRecord.totalDistanceUnit = attributeDict["totalDistanceUnit"] ??  ""
        currentRecord.totalEnergyBurned = Double(attributeDict["totalEnergyBurned"] ?? "0") ?? 0
        currentRecord.totalEnergyBurnedUnit = attributeDict["totalEnergyBurnedUnit"] ??  ""
        if let date = dateFormatter?.date(from: attributeDict["startDate"]!) {
            currentRecord.startDate = date
        }
        if let date = dateFormatter?.date(from: attributeDict["endDate"]!) {
            currentRecord.endDate = date
        }
        if currentRecord.startDate > currentRecord.endDate {
            currentRecord.startDate = currentRecord.endDate
        }
        if let date = dateFormatter?.date(from: attributeDict["creationDate"]!) {
            currentRecord.creationDate = date
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "Record" || elementName == "Workout" {
            readCount += 1
            if Constants.loggingEnabled {
                os_log("Record: %@", currentRecord.description)
            }
            DispatchQueue.main.async {
                self.onReadCountUpdated?(self.readCount)
            }
            if self.cutDate == nil || currentRecord.startDate > cutDate! {
                saveRecord(item: currentRecord, withSuccess: {}, failure: {
                    if Constants.loggingEnabled {
                        os_log("fail to process record")
                    }
                })
            }
            currentRecord = HealthRecord.init()
        }
    }

    func saveRecord(item: HealthRecord, withSuccess successBlock: @escaping () -> Void, failure failureBlock: @escaping () -> Void) {
        // HealthKit raises an exception if time between end and start date is > 345600
        let duration = item.endDate.timeIntervalSince(item.startDate)
        if duration > 345600 || (item.type == "HKQuantityTypeIdentifierHeadphoneAudioExposure" && duration < 0.001) {
            failureBlock()
            return
        }

        let unit = HKUnit.init(from: item.unit!)
        let quantity = HKQuantity(unit: unit, doubleValue: item.value)
        var hkSample: HKSample?
        if let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: item.type)) {
            hkSample = HKQuantitySample.init(
                type: type,
                quantity: quantity,
                start: item.startDate,
                end: item.endDate,
                metadata: item.metadata
            )
        } else if let type = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier(rawValue: item.type)) {
            hkSample = HKCategorySample.init(
                type: type,
                value: Int(item.value),
                start: item.startDate,
                end: item.endDate,
                metadata: item.metadata
            )
        } else if item.type == HKObjectType.workoutType().identifier {
            let workoutType = HKObjectType.workoutType()
            if authorizedTypes[workoutType] ?? false ||
                (self.healthStore?.authorizationStatus(for: workoutType) == HKAuthorizationStatus.sharingAuthorized) {
                authorizedTypes[workoutType] = true
                workoutRecords.append(item)
                successBlock()
            } else {
                failureBlock()
            }
            return
        } else if Constants.loggingEnabled {
            os_log("Didn't catch this item: %@", item.description)
        }
        if let hkSample = hkSample,
            authorizedTypes[hkSample.sampleType] ?? false || self.healthStore?.authorizationStatus(for: hkSample.sampleType) == HKAuthorizationStatus.sharingAuthorized {
            authorizedTypes[hkSample.sampleType] = true
            allSamples.append(hkSample)
            successBlock()
        } else {
            failureBlock()
        }
    }

    func saveAllSamples() {
        if self.allSamples.isEmpty {
            saveWorkouts(records: self.workoutRecords, withSuccess: {}, failure: {})
            return
        }

        saveSamples(samples: self.allSamples, withSuccess: {
            self.saveWorkouts(records: self.workoutRecords, withSuccess: {}, failure: {})
        }, failure: {
            self.saveWorkouts(records: self.workoutRecords, withSuccess: {}, failure: {})
        })
    }

    func saveSamples(samples: [HKSample], withSuccess successBlock: @escaping () -> Void, failure failureBlock: @escaping () -> Void) {
        self.healthStore?.save(samples, withCompletion: { (success, error) in
            if !success {
                if Constants.loggingEnabled {
                    os_log("An error occured saving the sample. The error was: %@.", error.debugDescription)
                }
                failureBlock()
            }
            self.incrementWriteCount(by: samples.count)
            successBlock()
        })
    }

}

extension Importer {
    func saveWorkouts(records: [HealthRecord], withSuccess successBlock: @escaping () -> Void, failure failureBlock: @escaping () -> Void) {
        if records.isEmpty {
            successBlock()
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var didFail = false

        for record in records {
            group.enter()
            saveWorkout(record: record, completion: { success in
                if !success {
                    lock.lock()
                    didFail = true
                    lock.unlock()
                }
                group.leave()
            })
        }

        group.notify(queue: .main) {
            if didFail {
                failureBlock()
            } else {
                successBlock()
            }
        }
    }

    func saveWorkout(record: HealthRecord, completion: @escaping (Bool) -> Void) {
        guard let healthStore = self.healthStore else {
            completion(false)
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = record.activityType ?? .other
        configuration.locationType = .unknown

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: nil)

        builder.beginCollection(withStart: record.startDate) { success, error in
            guard success else {
                if Constants.loggingEnabled {
                    os_log("Failed to begin workout collection: %@", error?.localizedDescription ?? "unknown error")
                }
                completion(false)
                return
            }
            self.addWorkoutMetadataAndFinish(builder: builder, record: record, completion: completion)
        }
    }

    private func addWorkoutMetadataAndFinish(builder: HKWorkoutBuilder, record: HealthRecord, completion: @escaping (Bool) -> Void) {
        if let metadata = record.metadata, !metadata.isEmpty {
            builder.addMetadata(metadata) { metadataSuccess, metadataError in
                guard metadataSuccess else {
                    if Constants.loggingEnabled {
                        os_log("Failed to add workout metadata: %@", metadataError?.localizedDescription ?? "unknown error")
                    }
                    completion(false)
                    return
                }
                self.endAndFinishWorkout(builder: builder, record: record, completion: completion)
            }
        } else {
            endAndFinishWorkout(builder: builder, record: record, completion: completion)
        }
    }

    private func endAndFinishWorkout(builder: HKWorkoutBuilder, record: HealthRecord, completion: @escaping (Bool) -> Void) {
        builder.endCollection(withEnd: record.endDate) { endSuccess, endError in
            guard endSuccess else {
                if Constants.loggingEnabled {
                    os_log("Failed to end workout collection: %@", endError?.localizedDescription ?? "unknown error")
                }
                completion(false)
                return
            }

            builder.finishWorkout { workout, finishError in
                guard workout != nil else {
                    if Constants.loggingEnabled {
                        os_log("Failed to finish workout: %@", finishError?.localizedDescription ?? "unknown error")
                    }
                    completion(false)
                    return
                }

                self.incrementWriteCount(by: 1)
                completion(true)
            }
        }
    }

    private func incrementWriteCount(by amount: Int) {
        DispatchQueue.main.async {
            self.writeCount += amount
            self.onWriteCountUpdated?(self.writeCount)
        }
    }
}
