#!/bin/bash

# set up the log
PUBLISHING_DIR="$PROJECT_DIR/Publishing"
mkdir $PUBLISHING_DIR

# set up the log
LOG="$PUBLISHING_DIR/IncrementBuildNumber.log"
/bin/rm -f $LOG
# printenv > $LOG

# where is this script executing?
echo >> $LOG
localwd=$(pwd)
echo "Working Directory is $localwd" >> $LOG

# increment the build number
propertyListFile="$PROJECT_DIR/$INFOPLIST_FILE"
echo "pList at $propertyListFile" >> $LOG
build_number=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$propertyListFile")
echo "Current Build Number is $build_number" >> $LOG
build_number=$(expr $build_number + 1)
echo "Next Build Number is $build_number" >> $LOG
/usr/libexec/Plistbuddy -c "Set CFBundleVersion $build_number" "$propertyListFile"
echo "Build Number Incremented to $build_number" >> $LOG

# check in this build
#cd $PROJECT_DIR
#svn ci --message archive.build.script

