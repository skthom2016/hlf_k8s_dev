export FABRIC_CFG_PATH=/var/hyperledger/fabric/config
configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock /var/hyperledger/genesis.block