./network.sh down
./network.sh up 
./network.sh channel create
# # ./network.sh anchor peer2 
./network.sh chaincode deploy 
./network.sh chaincode invoke '{"Args":["CreateAsset","1","blue","35","Pradeep","1000"]}' 
./network.sh chaincode invoke1 '{"Args":["CreateAsset","1","green","35","Santhosh","1000"]}' 
./network.sh chaincode query '{"Args":["ReadAsset","1"]}'
./network.sh application