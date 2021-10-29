## **Step 1:** Login to cloud shell and Clone the repo and cd into the directory
```
git clone https://github.com/denali49/fabric-ca-k8s.git && cd fabric-ca-k8s
```

## **Step 2:**Setup PVC and redis storage
```
kubectl apply -f setup-pvc.yaml -f redis-storage.yaml 
```
## **Step 3:**copy required scripts to the redis storage
```
kubectl cp ../scripts redis:/scripts/
```