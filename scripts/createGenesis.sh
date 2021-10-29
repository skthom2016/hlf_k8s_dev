
cd /

cp /scripts/configtx/configtx.yaml .

export FABRIC_CFG_PATH=${PWD}


configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block