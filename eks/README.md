4. DEPLOYMENT ORDER (VERY IMPORTANT)

Run in this order:

kubectl apply -f oracle-service.yaml
kubectl apply -f oracle-statefulset.yaml

Wait:

kubectl get pods

Then:

kubectl apply -f db-init-job.yaml
kubectl apply -f app-deployment.yaml
kubectl apply -f app-service.yaml
🧠 WHY THIS IS CORRECT DESIGN
Component	Type	Reason
Oracle DB	StatefulSet	stable storage + identity
App	Deployment	stateless
DB Init	Job	run once
Service	ClusterIP/LoadBalancer	access
⚠️ IMPORTANT EKS NOTES
You need a StorageClass (EBS)
Oracle takes 2–5 minutes to start
Wait before running Job
Use kubectl logs oracle-init-job to debug
