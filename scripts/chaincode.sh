#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# function package_chaincode_for() {
#   local org=$1
#   local cc_folder="chaincode/${CHAINCODE_NAME}"
#   local build_folder="build/chaincode"
#   local cc_archive="${build_folder}/${CHAINCODE_NAME}.tgz"
#   push_fn "Packaging chaincode folder ${cc_folder}"

#   mkdir -p ${build_folder}

#   tar -C ${cc_folder} -zcf ${cc_folder}/code.tar.gz connection.json
#   tar -C ${cc_folder} -zcf ${cc_archive} code.tar.gz metadata.json

#   rm ${cc_folder}/code.tar.gz

#   pop_fn
# }

function package_chaincode_for() {
  local org=$1
  local cc_folder="chaincode/${org}/${CHANNEL_NAME}/${CHAINCODE_NAME}"
  local build_folder="build/chaincode"
  local cc_archive="${build_folder}/${CHAINCODE_NAME}.tgz"
  push_fn "Packaging chaincode folder ${cc_folder}"

  rm -rf rm ${build_folder}
  mkdir -p ${build_folder}

  tar -C ${cc_folder} -zcf ${cc_folder}/code.tar.gz connection.json
  tar -C ${cc_folder} -zcf ${cc_archive} code.tar.gz metadata.json

  rm ${cc_folder}/code.tar.gz

  pop_fn
}
# Copy the chaincode archive from the local host to the org admin
function transfer_chaincode_archive_for() {
  local org=$1
  local cc_archive="build/chaincode/${CHAINCODE_NAME}.tgz"
  push_fn "Transferring chaincode archive to ${org}"

  # Like kubectl cp, but targeted to a deployment rather than an individual pod.
  tar cf - ${cc_archive} | kubectl -n $NS exec -i deploy/${org}-admin-cli -c main -- tar xvf -

  pop_fn
}

function install_chaincode_for() {
  local org=$1
  push_fn "Installing chaincode for org ${org}"

  # Install the chaincode
  echo 'set -x
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  peer lifecycle chaincode install build/chaincode/'${CHAINCODE_NAME}'.tgz
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash

  pop_fn
}

function launch_chaincode_service() {
  local org=$1
  local cc_id=$2
  local cc_image=$3
  push_fn "Launching chaincode container \"${cc_image}\""

  # The chaincode endpoint needs to have the generated chaincode ID available in the environment.
  # This could be from a config map, a secret, or by directly editing the deployment spec.  Here we'll keep
  # things simple by using sed to substitute script variables into a yaml template.
  cat kube/${org}/${org}-cc-template.yaml \
    | sed 's,{{CHAINCODE_NAME}},'${CHAINCODE_NAME}',g' \
    | sed 's,{{CHAINCODE_ID}},'${cc_id}',g' \
    | sed 's,{{CHAINCODE_IMAGE}},'${cc_image}',g' \
    | exec kubectl -n $NS apply -f -

  kubectl -n $NS rollout status deploy/${org}-cc-${CHAINCODE_NAME}

  pop_fn
}

function activate_chaincode_for() {
  local org=$1
  local cc_id=$2
  local channel=$3
  push_fn "Activating chaincode ${CHAINCODE_ID}"

  echo 'set -x 
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  
  # peer lifecycle \
  #   chaincode approveformyorg \
  #   --channelID '${channel}' \
  #   --name '${CHAINCODE_NAME}' \
  #   --version 1 \
  #   --package-id '${cc_id}' \
  #   --sequence 1 \
  #   -o org0-orderer1:6050 \
  #   --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  
  peer lifecycle \
    chaincode commit \
    --channelID '${channel}' \
    --name '${CHAINCODE_NAME}' \
    --version 1 \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash

  pop_fn
}

function approve_chaincode() {
  local org=$1
  local cc_id=$2
  local channel=$3
  push_fn "Approving chaincode ${CHAINCODE_ID} for ${org}"

  echo 'set -x 
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  
  peer lifecycle \
    chaincode approveformyorg \
    --channelID '${channel}' \
    --name '${CHAINCODE_NAME}' \
    --version 1 \
    --package-id '${cc_id}' \
    --sequence 1 \
    -o org0-orderer1:6050 \
    --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  
  # peer lifecycle \
  #   chaincode commit \
  #   --channelID '${channel}' \
  #   --name '${CHAINCODE_NAME}' \
  #   --version 1 \
  #   --sequence 1 \
  #   -o org0-orderer1:6050 \
  #   --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash

  pop_fn
}

function query_chaincode() {
  local org=$1  
  local param=$2
  set -x
  # todo: mangle additional $@ parameters with bash escape quotations
  echo '
  export CORE_PEER_ADDRESS='${org}'-peer1:7051
  peer chaincode query -n '${CHAINCODE_NAME}' -C '${CHANNEL_NAME}' -c '"'${param}'"'
  ' | exec kubectl -n $NS exec deploy/${org}-admin-cli -c main -i -- /bin/bash
}

# function query_chaincode1() {
#   set -x
#   # todo: mangle additional $@ parameters with bash escape quotations
#   echo '
#   export CORE_PEER_ADDRESS=org2-peer1:7051
#   peer chaincode query -n '${CHAINCODE_NAME}' -C '${CHANNEL_NAME}' -c '"'$@'"'
#   ' | exec kubectl -n $NS exec deploy/org2-admin-cli -c main -i -- /bin/bash
# }

function query_chaincode_metadata() {
  set -x
  local args='{"Args":["org.hyperledger.fabric:GetMetadata"]}'
  # todo: mangle additional $@ parameters with bash escape quotations
  echo '
  export CORE_PEER_ADDRESS=org1-peer1:7051
  peer chaincode query -n '${CHAINCODE_NAME}' -C '${CHANNEL_NAME}' -c '"'$args'"'
  ' | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash
}

function invoke_chaincode() {
  # set -x
  # todo: mangle additional $@ parameters with bash escape quotations
  echo '
  export CORE_PEER_ADDRESS=org1-peer1:7051
  peer chaincode \
    invoke \
    -o org0-orderer1:6050 \
    --tls --cafile /var/hyperledger/fabric/organizations/ordererOrganizations/org0.example.com/msp/tlscacerts/org0-tls-ca.pem \
    -n '${CHAINCODE_NAME}' \
    -C '${CHANNEL_NAME}' \
    -c '"'$@'"'
  ' | exec kubectl -n $NS exec deploy/org1-admin-cli -c main -i -- /bin/bash

  sleep 2
}

# Normally the chaincode ID is emitted by the peer install command.  In this case, we'll generate the
# package ID as the sha-256 checksum of the chaincode archive.
function set_chaincode_id() {
  local cc_sha256=$(shasum -a 256 build/chaincode/${CHAINCODE_NAME}.tgz | tr -s ' ' | cut -d ' ' -f 1)

  CHAINCODE_ID=${CHAINCODE_LABEL}:${cc_sha256}
}

# Package and install the chaincode, but do not activate.
function install_chaincode() {
  local org=$1

  package_chaincode_for ${org}
  transfer_chaincode_archive_for ${org}
  install_chaincode_for ${org}

  set_chaincode_id
  approve_chaincode ${org} $CHAINCODE_ID $CHANNEL_NAME
}

# Activate the installed chaincode but do not package/install a new archive.
function activate_chaincode() {
  local org=$1
  set -x

  set_chaincode_id
  echo $CHAINCODE_ID
  # approve_chaincode org2 $CHAINCODE_ID $CHANNEL_NAME
  activate_chaincode_for ${org} $CHAINCODE_ID $CHANNEL_NAME
  # activate_chaincode_for org1 $CHAINCODE_ID $CHANNEL_NAME1
  # activate_chaincode_for org2 $CHAINCODE_ID
  # activate_chaincode_for org3 $CHAINCODE_ID
}

# Install, launch, and activate the chaincode
function deploy_chaincode() {
  set -x

  CHANNEL_NAME=${TEST_NETWORK_CHANNEL_NAME:-org1org2channel}
  PROFILE=${TEST_NETWORK_PROFILE_NAME:-Org1Org2ApplicationGenesis}
  CHAINCODE_NAME=${TEST_NETWORK_CHAINCODE_NAME:-asset-transfer-basic}
  CHAINCODE_IMAGE=${TEST_NETWORK_CHAINCODE_IMAGE:-ghcr.io/hyperledgendary/fabric-ccaas-asset-transfer-basic}
  CHAINCODE_LABEL=${TEST_NETWORK_CHAINCODE_LABEL:-org1org2basic_1.0}

  install_chaincode org1
  launch_chaincode_service org1 $CHAINCODE_ID $CHAINCODE_IMAGE
  install_chaincode org2
  launch_chaincode_service org2 $CHAINCODE_ID $CHAINCODE_IMAGE
  activate_chaincode org2

  CHANNEL_NAME=${TEST_NETWORK_CHANNEL_NAME:-org1org3channel}
  PROFILE=${TEST_NETWORK_PROFILE_NAME:-Org1Org3ApplicationGenesis}
  CHAINCODE_NAME=${TEST_NETWORK_CHAINCODE_NAME:-asset-transfer-basic1}
  CHAINCODE_LABEL=${TEST_NETWORK_CHAINCODE_LABEL:-org1org3basic_1.0}

  install_chaincode org1
  launch_chaincode_service org1 $CHAINCODE_ID $CHAINCODE_IMAGE
  install_chaincode org3
  launch_chaincode_service org3 $CHAINCODE_ID $CHAINCODE_IMAGE
  activate_chaincode org3
  # install_chaincode org3
  # launch_chaincode_service org3 $CHAINCODE_ID $CHAINCODE_IMAGE
  # activate_chaincode org3

  # install_chaincode org3
  # launch_chaincode_service org3 $CHAINCODE_ID $CHAINCODE_IMAGE 
  
}

