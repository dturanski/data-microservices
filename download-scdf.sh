#!/bin/bash

if [[ $# -lt 2 ]]; then
   echo "usage $0 release-version (local,cloudfoundry,mesos)"
   exit
fi

SERVER="local"
if [[ ! -z "$2" ]]; then
	SERVER=$2
fi

VERSION=$1
echo "Downloading $VERSION $SERVER"


if [[ $VERSION == *"M"* ||  $VERSION == *"RC"* ]]; then
	REPO=milestone
elif [[ $VERSION == *"SNAPSHOT"* ]]; then
	REPO=snapshot
else
	REPO=release
fi

#
wget "http://repo.spring.io/$REPO/org/springframework/cloud/spring-cloud-dataflow-server-$SERVER/$VERSION/spring-cloud-dataflow-server-$SERVER-$VERSION.jar"
wget "http://repo.spring.io/$REPO/org/springframework/cloud/spring-cloud-dataflow-shell/$VERSION/spring-cloud-dataflow-shell-$VERSION.jar"