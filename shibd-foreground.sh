#!/bin/bash

set -e

/etc/init.d/shibd start

while true
do
	sleep 120
	STATUS=$(/etc/init.d/shibd status)
	if [ "$STATUS" != "shibd is running." ]
		then
		exit 1
	fi

done

exit 1
