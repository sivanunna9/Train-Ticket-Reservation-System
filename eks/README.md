# Kubernetes Deployment Guide

## Deployment Order (Very Important)

Follow the deployment sequence below to ensure all components start correctly and dependencies are available.

### 1. Deploy Oracle Service

```bash
kubectl apply -f oracle-service.yaml
```

### 2. Deploy Oracle StatefulSet

```bash
kubectl apply -f oracle-statefulset.yaml
```

### 3. Wait for Oracle Database to Start

Check the pod status and wait until the Oracle pod is in the **Running** state.

```bash
kubectl get pods
```

> **Note:** Oracle Database typically takes **2–5 minutes** to become fully operational.

### 4. Run Database Initialization Job

Once Oracle is running, deploy the database initialization job.

```bash
kubectl apply -f db-init-job.yaml
```

### 5. Deploy Application

```bash
kubectl apply -f app-deployment.yaml
```

### 6. Expose the Application

```bash
kubectl apply -f app-service.yaml
```

---

# Architecture Overview

| Component               | Kubernetes Resource      | Purpose                                                 |
| ----------------------- | ------------------------ | ------------------------------------------------------- |
| Oracle DB               | StatefulSet              | Provides stable storage and persistent network identity |
| Application             | Deployment               | Runs stateless application instances                    |
| Database Initialization | Job                      | Executes one-time database setup scripts                |
| Service                 | ClusterIP / LoadBalancer | Provides internal or external access to workloads       |

---

# Why This Design Is Correct

### Oracle Database → StatefulSet

A StatefulSet is used because databases require:

* Persistent storage
* Stable network identity
* Predictable pod naming
* Ordered startup and shutdown

### Application → Deployment

A Deployment is used because application pods are:

* Stateless
* Easily scalable
* Replaceable without data loss

### Database Initialization → Job

A Job is used because database setup should:

* Run only once
* Complete successfully
* Exit after execution

### Service → ClusterIP / LoadBalancer

Services provide:

* Stable network endpoints
* Internal cluster communication
* Optional external access through a LoadBalancer

---

# EKS-Specific Notes

## StorageClass Requirement

Amazon EKS requires a StorageClass backed by Amazon EBS for persistent Oracle database storage.

Verify available StorageClasses:

```bash
kubectl get storageclass
```

## Oracle Startup Time

Oracle containers require additional startup time.

Expected startup duration:

```text
2–5 minutes
```

Always verify the Oracle pod is running before executing the database initialization job.

## Debugging Database Initialization

To inspect the database initialization job logs:

```bash
kubectl logs job/oracle-init-job
```

Or find the pod first:

```bash
kubectl get pods
kubectl logs <oracle-init-job-pod-name>
```

---

# Recommended Deployment Workflow

```bash
# Deploy Oracle components
kubectl apply -f oracle-service.yaml
kubectl apply -f oracle-statefulset.yaml

# Wait until Oracle pod is Running
kubectl get pods

# Initialize database
kubectl apply -f db-init-job.yaml

# Deploy application
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml
```

---

# Verification

Check all resources:

```bash
kubectl get all
```

Check persistent volumes:

```bash
kubectl get pvc
kubectl get pv
```

Check services:

```bash
kubectl get svc
```

Check application logs:

```bash
kubectl logs -f deployment/<app-deployment-name>
```
