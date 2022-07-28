#!/bin/sh
set -e

# back up original files
[ -f /opt/lucee/web/context/Web.cfc ] && cp /opt/lucee/web/context/Web.cfc /tmp/Web.cfc
cp /opt/lucee/server/lucee-server/context/lucee-server.xml /tmp/lucee-server.xml
cp /opt/lucee/web/lucee-web.xml.cfm /tmp/lucee-web.xml.cfm

# put WebCompile.cfc in place
cp /opt/lucee/web/context/WebCompile.cfc /opt/lucee/web/context/Web.cfc
# set a static password
echo "luceedockercompilepassword" > "/opt/lucee/server/lucee-server/context/password.txt";

# clear log file to be watched
rm -f /opt/lucee/web/logs/docker-compile.log

# start lucee, watch for log file, time out after 90 seconds
timeoutCounter=1
export LUCEE_COMPILE=true && /usr/local/tomcat/bin/catalina.sh start
while [ ! -f "/opt/lucee/web/logs/docker-compile.log" ] && [ $timeoutCounter -le 90 ] ; do 
	sleep 1;
	timeoutCounter=$((timeoutCounter+1))
done

# debugging
cat /usr/local/tomcat/logs/catalina.out
cat /opt/lucee/web/logs/exception.log
ls -l /opt/lucee/web/cfclasses

# stop lucee and clean up
sleep 1
export LUCEE_COMPILE= && /usr/local/tomcat/bin/catalina.sh stop
sleep 3
rm -rf /opt/lucee/web/logs/*
rm -f /opt/lucee/server/lucee-server/context/password.txt
rm -f /opt/lucee/web/context/Web.cfc

# restore original files
[ -f /tmp/Web.cfc ] && cp /tmp/Web.cfc /opt/lucee/web/context/Web.cfc
cp /tmp/lucee-server.xml /opt/lucee/server/lucee-server/context/lucee-server.xml && rm -f /tmp/lucee-server.xml
cp /tmp/lucee-web.xml.cfm /opt/lucee/web/lucee-web.xml.cfm && rm -f /tmp/lucee-web.xml.cfm
