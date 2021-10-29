function askProceed() {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
  y | Y | "")
    echo "proceeding ..."
    ;;
  n | N)
    echo "exiting..."
    exit 1
    ;;
  *)
    echo "invalid response"
    askProceed
    ;;
  esac
}

clear
kubectl apply -f setup-pvc.yaml -f redis-storage.yaml 
# kubectl apply -f setup-pvc-azure.yaml -f redis-storage.yaml 
# kubectl apply -f setup-pvc-gcp.yaml -f redis-storage.yaml 
askProceed

kubectl cp ../scripts redis:/folder
kubectl exec redis /bin/bash /folder/scripts/cp_script.sh
kubectl exec redis ls  /folder
askProceed
# kubectl delete -f redis-storage.yaml
kubectl apply -f fabric-ca-deployment-orderer.yaml
kubectl apply -f fabric-ca-deployment-org1.yaml
kubectl apply -f fabric-ca-deployment-org2.yaml
kubectl apply -f fabric-ca-deployment-org3.yaml