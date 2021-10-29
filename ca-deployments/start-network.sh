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


./deleteall.sh

askProceed

./1-network.sh
askProceed
clear
./2-network.sh
askProceed
kubectl exec redis /bin/bash /folder/cp_ord_cacerts.sh
askProceed
clear
./3-network.sh
askProceed
clear
./4-network.sh
askProceed
clear
./5-network.sh
askProceed
clear
kubectl apply -f peer0Org1.yaml
kubectl apply -f peer0Org2.yaml
kubectl apply -f peer0Org3.yaml