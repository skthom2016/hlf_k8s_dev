clear
echo "*****************************"
echo "Deleting existing network and artifacts"
echo "*****************************"

kubectl delete -f orderer.yaml
kubectl delete -f create-artifacts.yaml
kubectl delete -f job_orderercert.yaml 
kubectl delete -f job_org1cert.yaml
kubectl delete -f job_org2cert.yaml
kubectl delete -f job_org3cert.yaml
kubectl delete -f fabric-ca-deployment-orderer.yaml 
kubectl delete -f fabric-ca-deployment-org1.yaml
kubectl delete -f fabric-ca-deployment-org2.yaml
kubectl delete -f fabric-ca-deployment-org3.yaml
kubectl delete -f setup-pvc.yaml -f redis-storage.yaml
sleep 10
echo "*****************************"
echo "creating new network"
echo "*****************************"

kubectl apply -f setup-pvc.yaml -f redis-storage.yaml 
sleep 5
kubectl cp ../scripts redis:/folder
kubectl delete -f redis-storage.yaml
kubectl apply -f fabric-ca-deployment-orderer.yaml
kubectl apply -f fabric-ca-deployment-org1.yaml
kubectl apply -f fabric-ca-deployment-org2.yaml
kubectl apply -f fabric-ca-deployment-org3.yaml
sleep 30
echo "*****************************"
echo "Creating Certificates"
echo "*****************************"

kubectl apply -f job_orderercert.yaml 
kubectl apply -f job_org1cert.yaml
kubectl apply -f job_org2cert.yaml
kubectl apply -f job_org3cert.yaml
sleep 10

echo "*****************************"
echo "Creating artifacts"
echo "*****************************"

kubectl apply -f create-artifacts.yaml
# sleep 1
# kubectl delete -f fabric-ca-deployment-orderer.yaml 
# kubectl delete -f fabric-ca-deployment-org1.yaml
# kubectl delete -f fabric-ca-deployment-org2.yaml
# kubectl delete -f fabric-ca-deployment-org3.yaml
# sleep 10
kubectl apply -f orderer.yaml