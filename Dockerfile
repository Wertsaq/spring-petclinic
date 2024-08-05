FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

COPY target/spring-petclinic-*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
