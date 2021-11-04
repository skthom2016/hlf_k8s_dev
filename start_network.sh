./network.sh up 
./network.sh channel create
# # ./network.sh anchor peer2 
./network.sh chaincode deploy 
./network.sh chaincode invoke '{"Args":["CreateAsset","1","blue","35","tom","1000"]}' 
./network.sh chaincode query '{"Args":["ReadAsset","1"]}'