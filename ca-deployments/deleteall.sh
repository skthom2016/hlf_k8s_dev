clear
kubectl delete -f peer0Org1.yaml
kubectl delete -f peer0Org2.yaml
kubectl delete -f peer0Org3.yaml
kubectl delete -f orderer.yaml
kubectl delete -f orderer-svc.yaml
kubectl delete -f orderer2.yaml
kubectl delete -f orderer2-svc.yaml
kubectl delete -f orderer3.yaml
kubectl delete -f orderer3-svc.yaml
kubectl delete -f orderer4.yaml
kubectl delete -f orderer4-svc.yaml
kubectl delete -f orderer5.yaml
kubectl delete -f orderer5-svc.yaml
kubectl delete -f create-artifacts.yaml
kubectl delete -f job_orderercert.yaml 
kubectl delete -f job_org1cert.yaml
kubectl delete -f job_org2cert.yaml
kubectl delete -f job_org3cert.yaml
kubectl delete -f fabric-ca-deployment-orderer.yaml 
kubectl delete -f fabric-ca-deployment-org1.yaml
kubectl delete -f fabric-ca-deployment-org2.yaml
kubectl delete -f fabric-ca-deployment-org3.yaml
kubectl delete -f redis-storage.yaml
kubectl delete -f setup-pvc.yaml 
kubectl delete -f setup-pvc-azure.yaml 
clear