# JFrog Artifactory OSS Setup for Maven Repository

This guide explains how to:

1. Run JFrog Artifactory OSS using Docker
2. Create Maven repositories in Artifactory
3. Configure Maven authentication
4. Deploy Maven artifacts to Artifactory

---

## Prerequisites

* Docker installed
* Java and Maven installed
* EC2/Linux server with at least 4 GB RAM
* Ports 8081 and 8082 open in the firewall/security group

---

# Step 1: Create a Docker Volume

```bash
docker volume create artifactory-data
```

Verify:

```bash
docker volume ls
```

---

# Step 2: Start JFrog Artifactory OSS

```bash
docker run -d \
  --name artifactory \
  -p 8081:8081 \
  -p 8082:8082 \
  -v artifactory-data:/var/opt/jfrog/artifactory \
  releases-docker.jfrog.io/jfrog/artifactory-oss:7.77.3
```

Verify container status:

```bash
docker ps
```

View logs:

```bash
docker logs -f artifactory
```

---

# Step 3: Access Artifactory UI

Open a browser:

```text
http://<SERVER-IP>:8082/ui
```

Example:

```text
http://54.123.45.67:8082/ui
```

Default credentials:

```text
Username: admin
Password: password
```

Change the password after first login.

---

# Step 4: Create Maven Repositories

Navigate to:

```text
Administration → Repositories → Repositories
```

## Create Release Repository

* Repository Type: Local
* Package Type: Maven
* Repository Key:

```text
maven-releases
```

* Handle Releases: Enabled
* Handle Snapshots: Disabled

Save the repository.

---

## Create Snapshot Repository

* Repository Type: Local
* Package Type: Maven
* Repository Key:

```text
maven-snapshots
```

* Handle Releases: Disabled
* Handle Snapshots: Enabled

Save the repository.

---

# Step 5: Create a Virtual Maven Repository (Recommended)

Navigate to:

```text
Administration → Repositories → Virtual
```

Create:

```text
maven
```

Include:

```text
maven-releases
maven-snapshots
```

Save the repository.

---

# Step 6: Configure Maven Authentication

Edit:

```bash
~/.m2/settings.xml
```

Add:

```xml
<settings>
    <servers>
        <server>
            <id>artifactory</id>
            <username>admin</username>
            <password>YOUR_PASSWORD_OR_TOKEN</password>
        </server>
    </servers>
</settings>
```

Example:

```xml
<settings>
    <servers>
        <server>
            <id>artifactory</id>
            <username>admin</username>
            <password>Admin@123</password>
        </server>
    </servers>
</settings>
```

---

# Step 7: Configure Maven Deployment

Add the following section to your `pom.xml`.

```xml
<distributionManagement>

    <repository>
        <id>artifactory</id>
        <url>http://YOUR_ARTIFACTORY_HOST:8082/artifactory/maven-releases</url>
    </repository>

    <snapshotRepository>
        <id>artifactory</id>
        <url>http://YOUR_ARTIFACTORY_HOST:8082/artifactory/maven-snapshots</url>
    </snapshotRepository>

</distributionManagement>
```

Example:

```xml
<distributionManagement>

    <repository>
        <id>artifactory</id>
        <url>http://54.123.45.67:8082/artifactory/maven-releases</url>
    </repository>

    <snapshotRepository>
        <id>artifactory</id>
        <url>http://54.123.45.67:8082/artifactory/maven-snapshots</url>
    </snapshotRepository>

</distributionManagement>
```

---

# Step 8: Build and Deploy Artifact

Build and deploy:

```bash
mvn clean deploy
```

Expected output:

```text
BUILD SUCCESS
Uploaded to artifactory
```

---

# Step 9: Verify Artifact Upload

Navigate to:

```text
Artifacts → maven-releases
```

Example structure:

```text
com/
└── company/
    └── sample-app/
        └── 1.0.0/
            ├── sample-app-1.0.0.jar
            ├── sample-app-1.0.0.pom
            └── maven-metadata.xml
```

---

# Common Docker Commands

Check running containers:

```bash
docker ps
```

Stop Artifactory:

```bash
docker stop artifactory
```

Start Artifactory:

```bash
docker start artifactory
```

Restart Artifactory:

```bash
docker restart artifactory
```

View logs:

```bash
docker logs -f artifactory
```

Remove container:

```bash
docker rm -f artifactory
```

---

# Troubleshooting

## Container Not Starting

Check logs:

```bash
docker logs artifactory
```

---

## Port Already in Use

Check:

```bash
sudo netstat -tulpn | grep 8082
```

---

## Authentication Failure During Deployment

Verify:

* `settings.xml` contains correct username/password.
* `<id>` in `pom.xml` matches the `<id>` in `settings.xml`.

Correct:

```xml
<id>artifactory</id>
```

---

## Verify Maven Connectivity

```bash
curl -I http://<SERVER-IP>:8082
```

Expected response:

```text
HTTP/1.1 200 OK
```

---

# Useful URLs

Artifactory UI:

```text
http://<SERVER-IP>:8082/ui
```

Release Repository:

```text
http://<SERVER-IP>:8082/artifactory/maven-releases
```

Snapshot Repository:

```text
http://<SERVER-IP>:8082/artifactory/maven-snapshots
```

Virtual Repository:

```text
http://<SERVER-IP>:8082/artifactory/maven
```
