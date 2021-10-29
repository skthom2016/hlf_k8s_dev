kubectl apply -f orderer.yaml
kubectl apply -f orderer-svc.yaml
sleep 10
kubectl apply -f orderer2.yaml
kubectl apply -f orderer2-svc.yaml
sleep 10
kubectl apply -f orderer3.yaml
kubectl apply -f orderer3-svc.yaml
sleep 10
kubectl apply -f orderer4.yaml
kubectl apply -f orderer4-svc.yaml
sleep 10
kubectl apply -f orderer5.yaml
kubectl apply -f orderer5-svc.yaml