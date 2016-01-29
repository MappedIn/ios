#!/bin/sh

#   framework-swap.sh
#   Copy the framework with the correct architecture for your build into the one used for building

set -e
set +u
# Avoid recursively calling this script.
if [[ $FRAMEWORK_COPY_SCRIPT_RUNNING ]]
then
exit 0
fi
set -u
export FRAMEWORK_COPY_SCRIPT_RUNNING=1

echo "Swapping frameworks"

# Constants
FRAMEWORK="../MappedIn.framework"
FRAMEWORK_SIM="../Common/MappedIn-iphonesimulator.framework"
FRAMEWORK_DEVICE="../Common/MappedIn-iphoneos.framework"

# Take build target
if [[ "$SDK_NAME" =~ ([A-Za-z]+) ]]
then
SF_SDK_PLATFORM=${BASH_REMATCH[1]}
else
echo "Could not find platform name from SDK_NAME: $SDK_NAME"
exit 1
fi

if [ -d "${FRAMEWORK}" ]
then
echo "Removing old framework"
rm -r "${FRAMEWORK}"
fi
if [[ "$SF_SDK_PLATFORM" = "iphoneos" ]]
then
cp -r "${FRAMEWORK_DEVICE}" "${FRAMEWORK}"
else
cp -r "${FRAMEWORK_SIM}" "${FRAMEWORK}"
fi

echo "Swap complete"
exit 0
