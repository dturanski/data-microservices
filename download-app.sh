#!/bin/bash

if [[ $# -lt 2 ]]; then
   echo "usage $0 appname version"
   exit
fi



APP=$1
VERSION=$2
echo "Downloading $APP $VERSION"


if [[ $VERSION == *"M"* ||  $VERSION == *"RC"* ]]; then
	REPO=milestone
elif [[ $VERSION == *"SNAPSHOT"* ]]; then
	REPO=snapshot
else
	REPO=release
fi

#
wget "https://repo.spring.io/libs-$REPO/org/springframework/cloud/stream/app/$APP/$VERSION/$APP-$VERSION.jar"
