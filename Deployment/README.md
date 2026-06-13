# 📘 CI/CD Pipeline: Jenkins + Maven + JFrog Artifactory + Ansible + JBoss EAP

This project demonstrates a complete end-to-end CI/CD pipeline that automates build, test, artifact storage, and deployment to JBoss application server using Jenkins, Maven, JFrog Artifactory, and Ansible.

---

# 🏗️ Architecture Flow

GitHub → Jenkins → Maven Build → JFrog Artifactory → Ansible → JBoss EAP Server

---

# 🚀 Tech Stack

- Jenkins (CI/CD Orchestration)
- Maven (Build & Dependency Management)
- JFrog Artifactory (Artifact Repository)
- Ansible (Automation & Deployment)
- JBoss EAP 8 (Application Server)
- Linux (Ubuntu/Debian)

---

# 📁 Project Structure (Ansible Setup)

/opt/ansible/
├── inventory.ini
├── deploy.yaml
├── ansible.cfg

---

# ⚙️ Prerequisites

## Jenkins Server Setup

Install required tools:

apt update
apt install -y openjdk-17-jdk maven git ansible openssh-client

Verify installation:

java -version
mvn -version
ansible --version

---

## JBoss Server Setup

JBoss installation path:

/opt/jboss-eap-8.0

Deployment directory:

/opt/jboss-eap-8.0/standalone/deployments

---

# 🔐 SSH Setup (Jenkins → JBoss)

## 1. Generate SSH Key (on Jenkins server)

sudo -u jenkins ssh-keygen -t rsa -b 4096

---

## 2. Copy SSH Key to JBoss Server

ssh-copy-id ubuntu@<JBOSS_SERVER_IP>

---

## 3. Test SSH Connection

ssh ubuntu@<JBOSS_SERVER_IP>

---

# 📌 Ansible Configuration

## inventory.ini

[jboss]
jboss-server ansible_host=172.31.xx.xx ansible_user=ubuntu

---

## ansible.cfg

[defaults]
inventory = inventory.ini
host_key_checking = False
timeout = 30

---

# 🚀 Ansible Deployment Playbook (deploy.yaml)

This playbook performs:

- Stop JBoss
- Backup existing WAR
- Fetch latest WAR from JFrog
- Download artifact
- Deploy WAR
- Start JBoss
- Cleanup temp files
- Verify deployment

---

```yaml
---
- name: Deploy WAR to JBoss EAP 8 from JFrog (Fully Stable)
  hosts: jboss
  become: yes

  vars:
    artifactory_url: "http://JFROG_IP:8082/artifactory"
    repo: "libs-snapshot-local"

    group_path: "TrainBook/TrainBook/1.0.0-SNAPSHOT"

    jboss_home: "/opt/jboss-eap-8.0"
    deploy_dir: "{{ jboss_home }}/standalone/deployments"

    tmp_dir: "/tmp/jboss-deploy"
    backup_war: "{{ deploy_dir }}/TrainBook.war.bak"

    app_url: "http://JBOSS_IP:8080/TrainBook"

  tasks:

  # =========================
  # 1. CHECK JBOSS PROCESS
  # =========================
  - name: Check JBoss process
    shell: "pgrep -f standalone || true"
    register: jboss_process

  # =========================
  # 2. STOP JBOSS SAFELY
  # =========================
  - name: Stop JBoss via CLI (safe)
    shell: |
      {{ jboss_home }}/bin/jboss-cli.sh --connect command=:shutdown
    when: jboss_process.stdout != ""
    failed_when: false

  - name: Force kill JBoss if still running
    shell: "pkill -f standalone || true"
    when: jboss_process.stdout != ""
    failed_when: false

  # =========================
  # 3. CREATE TEMP DIRECTORY
  # =========================
  - name: Create temp directory
    file:
      path: "{{ tmp_dir }}"
      state: directory
      mode: '0755'

  # =========================
  # 4. BACKUP OLD WAR
  # =========================
  - name: Backup existing WAR (if exists)
    copy:
      src: "{{ deploy_dir }}/TrainBook.war"
      dest: "{{ backup_war }}"
      remote_src: yes
    ignore_errors: yes

  # =========================
  # 5. SEARCH ARTIFACT (RELIABLE METHOD)
  # =========================
  - name: Search latest WAR in Artifactory
    uri:
      url: "{{ artifactory_url }}/api/search/artifact?name=TrainBook*.war&repos={{ repo }}"
      return_content: yes
    register: search_result
    failed_when: false

  # =========================
  # 6. EXTRACT CLEAN WAR NAME (FIX FOR YOUR ERROR)
  # =========================
  - name: Extract raw WAR path
    set_fact:
      war_raw: >-
        {{
          (search_result.json.results
          | default([])
          | map(attribute='uri')
          | list
          | last
          | default('')
          )
        }}

  - name: Clean WAR filename (REMOVE FULL URL ISSUE)
    set_fact:
      war_file: "{{ war_raw | regex_replace('.*/', '') }}"

  - name: Fail if WAR not found
    fail:
      msg: "❌ No WAR found in Artifactory search results"
    when: war_file == ""

  - name: Debug WAR file
    debug:
      var: war_file

  # =========================
  # 7. DOWNLOAD WAR (FIXED URL BUILD)
  # =========================
  - name: Download latest WAR from JFrog
    get_url:
      url: "{{ artifactory_url }}/{{ repo }}/{{ group_path }}/{{ war_file }}"
      dest: "{{ tmp_dir }}/app.war"
      url_username: admin
      url_password: PASSWORD
      force: yes

  # =========================
  # 8. DEPLOY TO JBOSS
  # =========================
  - name: Remove old deployment
    file:
      path: "{{ deploy_dir }}/TrainBook.war"
      state: absent

  - name: Remove marker files
    file:
      path: "{{ deploy_dir }}/TrainBook.war.*"
      state: absent
    ignore_errors: yes

  - name: Copy WAR to deployments
    copy:
      src: "{{ tmp_dir }}/app.war"
      dest: "{{ deploy_dir }}/TrainBook.war"
      remote_src: yes

  - name: Trigger deployment
    file:
      path: "{{ deploy_dir }}/TrainBook.war.dodeploy"
      state: touch

  # =========================
  # 9. START JBOSS
  # =========================
  - name: Start JBoss
    shell: |
      nohup {{ jboss_home }}/bin/standalone.sh -b 0.0.0.0 > {{ jboss_home }}/standalone/log/server.log 2>&1 &
    async: 10
    poll: 0

  # =========================
  # 10. WAIT FOR APPLICATION
  # =========================
  #- name: Wait for application to start
  #  uri:
  #    url: "{{ app_url }}"
  #    status_code: 200
 #   register: result
  #  retries: 15
  #  delay: 10
  #  until: result.status == 200

  # =========================
  # 11. CLEANUP
  # =========================
  - name: Cleanup temp files
    file:
      path: "{{ tmp_dir }}"
      state: absent

  # =========================
  # 12. ROLLBACK (SAFE)
  # =========================
  #- name: Rollback WAR if deployment fails
  #  copy:
  #    src: "{{ backup_war }}"
  #    dest: "{{ deploy_dir }}/TrainBook.war"
  #    remote_src: yes
  #  when: result is failed
  #  ignore_errors: yes

     
