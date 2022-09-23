FROM docker.io/library/tomcat:9.0-jdk8-openjdk

ENV LUCEE_IMAGE=lucee/lucee:5.3.9.160
ENV TOMCAT_VERSION=9.0
ENV TOMCAT_JAVA_VERSION=jdk8-openjdk
ENV TOMCAT_BASE_IMAGE=
ENV LUCEE_MINOR=5.3
ENV LUCEE_SERVER=
ENV LUCEE_VARIANTS=
ENV LUCEE_VERSION=5.3.9.160
ENV LUCEE_JAR_URL=https://release.lucee.org/rest/update/provider/loader/5.3.9.160

RUN echo ver: $LUCEE_VERSION minor: $LUCEE_MINOR server: $LUCEE_SERVER variant: $LUCEE_VARIANT jar: $LUCEE_JAR_URL

# Replace the Trusted SSL Certificates packaged with Lucee with those from
# Java. Different OpenJDK versions have different paths for cacerts
RUN mkdir -p /opt/lucee/server/lucee-server/context/security && \
	if   [ -e "$JAVA_HOME/jre/lib/security/cacerts" ]; then ln -s "$JAVA_HOME/jre/lib/security/cacerts" -t /opt/lucee/server/lucee-server/context/security/; \
	elif [ -e "$JAVA_HOME/lib/security/cacerts" ]; then ln -s "$JAVA_HOME/lib/security/cacerts" -t /opt/lucee/server/lucee-server/context/security/; \
	else echo "Unable to find/symlink cacerts."; exit 1; fi

# Delete the default Tomcat webapps so they aren't deployed at startup
RUN rm -rf /usr/local/tomcat/webapps/*

# Custom setenv.sh to load Lucee
# Tomcat memory settings
# -Xms<size> set initial Java heap size
# -Xmx<size> set maximum Java heap size
ENV LUCEE_JAVA_OPTS "-Xms64m -Xmx512m"

# Download Lucee JAR
RUN mkdir -p /usr/local/tomcat/lucee
ADD ${LUCEE_JAR_URL} /usr/local/tomcat/lucee/lucee.jar

# Delete the default Tomcat webapps so they aren't deployed at startup
RUN rm -rf /usr/local/tomcat/webapps/*

# Set Tomcat config to load Lucee
COPY /config/lucee/catalina.properties \
	/config/lucee/server.xml \
	/config/lucee/web.xml \
	/usr/local/tomcat/conf/

# Custom setenv.sh to load Lucee
COPY /config/supporting/setenv.sh /usr/local/tomcat/bin/
RUN chmod a+x /usr/local/tomcat/bin/setenv.sh

# Create Lucee configs
COPY /config/lucee/lucee-server.xml /opt/lucee/server/lucee-server/context/lucee-server.xml
COPY /config/lucee/lucee-web.xml.cfm /opt/lucee/web/lucee-web.xml.cfm

# Provide test page
RUN mkdir -p /var/www
COPY www/ /var/www/
ONBUILD RUN rm -rf /var/www/*

# lucee first time startup; explodes lucee and installs bundles/extensions (prewarms twice due to additional bundle downloads)
COPY /config/supporting/prewarm.sh /usr/local/tomcat/bin/
RUN chmod +x /usr/local/tomcat/bin/prewarm.sh
RUN /usr/local/tomcat/bin/prewarm.sh && /usr/local/tomcat/bin/prewarm.sh

# --------

RUN apt-get update && \
    apt-get upgrade -y && \
	apt-get install -y \
		supervisor \
		apache2 \
		libapache2-mod-shib \
	&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY config/apache2/ /etc/apache2/
COPY config/shibboleth3/ /etc/shibboleth/
COPY config/supervisor/ /etc/supervisor/conf.d/
COPY shibd-foreground.sh /usr/bin/shibd-foreground.sh
RUN chmod +x /usr/bin/shibd-foreground.sh

ONBUILD RUN rm -rf /var/www/*

EXPOSE 80 443

CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
