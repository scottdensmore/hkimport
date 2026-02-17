#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVELOPER_SETTINGS_PATH="${SCRIPT_DIR}/DeveloperSettings.xcconfig"

cat << "EOF"
 _   _ _  _____                                 _
| | | | |/ /_ _|_ __ ___  _ __   ___  _ __ ___| |_
| |_| | ' / | || '_ ` _ \| '_ \ / _ \| '__/ __| __|
|  _  | . \ | || | | | | | |_) | (_) | |  \__ \ |_
|_| |_|_|\_\___|_| |_| |_| .__/ \___/|_|  |___/\__|
                         |_|

EOF

echo "This script will create DeveloperSettings.xcconfig."
echo
echo "We need to ask a few questions first."
echo
read -r -p "Press enter to get started."

echo "1. What is your Developer Team ID? You can get this from developer.apple.com."
read -r devTeamID

echo "2. What is your organization identifier? e.g. com.developername"
read -r devOrgName

echo "Creating ${DEVELOPER_SETTINGS_PATH}"

cat <<file > "${DEVELOPER_SETTINGS_PATH}"
CODE_SIGN_IDENTITY = Apple Development
DEVELOPMENT_TEAM = $devTeamID
CODE_SIGN_STYLE = Automatic
ORGANIZATION_IDENTIFIER = $devOrgName
file

echo "Done!"

if git -C "${SCRIPT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "${SCRIPT_DIR}" config core.hooksPath .githooks
  echo "Configured repo git hooks (.githooks)."
fi
