#!/bin/bash

cat << "EOF"
 __    __   __  ___  __  .___  ___. .______     ______   .______     .___________.
|  |  |  | |  |/  / |  | |   \/   | |   _  \   /  __  \  |   _  \    |           |
|  |__|  | |  '  /  |  | |  \  /  | |  |_)  | |  |  |  | |  |_)  |   `---|  |----`
|   __   | |    <   |  | |  |\/|  | |   ___/  |  |  |  | |      /        |  |     
|  |  |  | |  .  \  |  | |  |  |  | |  |      |  `--'  | |  |\  \----.   |  |     
|__|  |__| |__|\__\ |__| |__|  |__| | _|       \______/  | _| `._____|   |__|     
                                                                                  

EOF

echo This script will create a DeveloperSettings.xcconfig file.
echo 
echo We need to ask a few questions first.
echo 
read -p "Press enter to get started."


# Get the user's Developer Team ID
echo 1. What is your Developer Team ID? You can get this from developer.apple.com.
read devTeamID

# Get the user's Org Identifier
echo 2. What is your organisation identifier? e.g. com.developername
read devOrgName

echo Creating DeveloperSettings.xcconfig

cat <<file >> DeveloperSettings.xcconfig
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = $devTeamID
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = $devOrgName
file

echo Done! 
