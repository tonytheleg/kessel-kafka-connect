# Leverages Streams for Apache Kafka Images
# Streams for Apache Kafka 2.9 is based on Apache Kafka 3.9.0 and Strimzi 0.45.x.
FROM registry.redhat.io/amq-streams/kafka-39-rhel9:2.9.1-2
USER root:root

# Notes on ENV settings and variables
# DEBEZIUM_MAVEN_VERSION = Maven Package Version (x.x.x.FINAL) - https://mvnrepository.com/artifact/io.debezium/debezium-connector-postgres)
# DEBEZIUM_RELEASE_VERSION = x.y release version (matches x.y of Maven Package Version)
# DEBEZIUM_TARBALL_MD5 = md5 value of tar.gz file from Maven (set by script)
# DEBEZIUM_SCRIPTING_TARBALL_MD5 = md5 value from tar.gz file from Maven (set by script)

# Update the debezium maven and release versions to update Debezium and related plugins
ENV KAFKA_CONNECT_PLUGINS_DIR=/opt/kafka/plugins \
    EXTERNAL_LIBS_DIR=/opt/kafka/libs \
    DEBEZIUM_MAVEN_VERSION=2.7.3.Final \
    DEBEZIUM_RELEASE_VERSION=2.7

RUN rm -rf /opt/kafka-exporter

# The docker-maven-downlad script is a handy tool to add packages/plugins from Maven
# Review the info at the start of the script for more details on use:
RUN mkdir -p "$KAFKA_CONNECT_PLUGINS_DIR" "$EXTERNAL_LIBS_DIR" && \
    DEBEZIUM_TARBALL_MD5=$(curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/${DEBEZIUM_MAVEN_VERSION}/debezium-connector-postgres-${DEBEZIUM_MAVEN_VERSION}-plugin.tar.gz.md5) && \
    DEBEZIUM_SCRIPTING_TARBALL_MD5=$(curl https://repo1.maven.org/maven2/io/debezium/debezium-scripting/${DEBEZIUM_MAVEN_VERSION}/debezium-scripting-${DEBEZIUM_MAVEN_VERSION}.tar.gz.md5) && \
    curl -o /usr/local/bin/docker-maven-download https://raw.githubusercontent.com/debezium/container-images/refs/heads/main/connect-base/${DEBEZIUM_RELEASE_VERSION}/docker-maven-download.sh && \
    chmod +x /usr/local/bin/docker-maven-download && \
    docker-maven-download debezium postgres "$DEBEZIUM_MAVEN_VERSION" "$DEBEZIUM_TARBALL_MD5" && \
    docker-maven-download debezium-optional scripting "$DEBEZIUM_MAVEN_VERSION" "$DEBEZIUM_SCRIPTING_TARBALL_MD5"

USER 1001
