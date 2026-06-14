FROM maven:3.8.7-eclipse-temurin-8 AS builder

WORKDIR /app

COPY . .

RUN mvn clean package -DskipTests

FROM tomcat:8.5-jdk8-temurin

RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy WAR
COPY --from=builder /app/target/*.war \
    /usr/local/tomcat/webapps/ROOT.war

# Copy application.properties (ONLY if your code reads external file)
COPY src/application.properties /usr/local/tomcat/conf/application.properties

EXPOSE 8080

CMD ["catalina.sh", "run"]
