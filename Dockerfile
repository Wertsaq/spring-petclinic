FROM maven:3.9.8-eclipse-temurin-21-jammy

WORKDIR /app

ARG NEXUS_IP_PORT

ENV BASE_URL="http://${NEXUS_IP_PORT}/repository/maven-nexus-repo/org/springframework/samples/spring-petclinic/3.3.0-SNAPSHOT"
ENV METADATA_URL="${BASE_URL}/maven-metadata.xml"

RUN apt-get update && \
    apt-get install -y curl libxml2-utils && \
    curl -o maven-metadata.xml $METADATA_URL && \
    LATEST_VERSION=$(xmllint --xpath "string(//snapshotVersion[extension='jar']/value)" maven-metadata.xml) && \
    JAR_URL="${BASE_URL}/spring-petclinic-${LATEST_VERSION}.jar" && \
    curl -L -o spring-petclinic.jar $JAR_URL

ENTRYPOINT ["java", "-jar", "spring-petclinic.jar"]
