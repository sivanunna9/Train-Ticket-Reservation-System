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
- name: Deploy WAR to JBoss from JFrog
  hosts: jboss
  become: yes

  vars:
    jboss_home: /opt/jboss-eap-8.0
    deploy_dir: "{{ jboss_home }}/standalone/deployments"
    tmp_dir: /tmp/jboss-deploy
    war_name: TrainBook.war

  tasks:

    - name: Stop JBoss gracefully
      shell: "{{ jboss_home }}/bin/jboss-cli.sh --connect command=:shutdown"
      ignore_errors: yes

    - name: Force kill JBoss if running
      shell: "pkill -f standalone || true"
      ignore_errors: yes

    - name: Create temp directory
      file:
        path: "{{ tmp_dir }}"
        state: directory
        mode: '0755'

    - name: Backup existing WAR
      shell: |
        if [ -f {{ deploy_dir }}/{{ war_name }} ]; then
          cp {{ deploy_dir }}/{{ war_name }} {{ deploy_dir }}/{{ war_name }}.bak
        fi
      ignore_errors: yes

    - name: Get latest WAR metadata from Artifactory
      uri:
        url: "http://<JFROG_URL>/artifactory/api/storage/libs-snapshot-local/TrainBook/TrainBook/1.0.0-SNAPSHOT/"
        method: GET
        return_content: yes
      register: art_info

    - name: Extract latest WAR file
      set_fact:
        war_file: "{{ (art_info.json.children | selectattr('uri','search','.war') | list | last).uri }}"

    - name: Download WAR from Artifactory
      get_url:
        url: "http://<JFROG_URL>/artifactory/libs-snapshot-local/TrainBook/TrainBook/1.0.0-SNAPSHOT{{ war_file }}"
        dest: "{{ tmp_dir }}/{{ war_name }}"
        url_username: admin
        url_password: YOUR_PASSWORD
        force: yes

    - name: Deploy WAR to JBoss
      copy:
        src: "{{ tmp_dir }}/{{ war_name }}"
        dest: "{{ deploy_dir }}/{{ war_name }}"
        remote_src: yes

    - name: Start JBoss
      shell: "nohup {{ jboss_home }}/bin/standalone.sh -b 0.0.0.0 > /dev/null 2>&1 &"

    - name: Cleanup temp files
      file:
        path: "{{ tmp_dir }}"
        state: absent

    - name: Verify deployment
      stat:
        path: "{{ deploy_dir }}/{{ war_name }}"
      register: war_check

    - name: Fail if deployment failed
      fail:
        msg: "WAR deployment failed"
      when: not war_check.stat.exists
