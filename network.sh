#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
set -o errexit

# todo: better handling for input parameters.
# todo: skip storage volume init if deploying to a remote / cloud cluster (ICP IKS ROKS etc...)
# todo: for logging, set up a stack and allow multi-line status output codes
# todo: refactor - lots of for-org-in-0-to-2-...
# todo: find a better technique for passing input commands to a remote kube exec
# todo: register tls csr.hosts w/ kube DNS domain .NS.svc.cluster.local
# todo: user:pass auth for tls and ecert bootstrap admins.  here and in the server-config.yaml
# todo: set tls.certfiles= ... arg in deployment env / yaml
# todo: refactor chaincode install to support other chaincode routines
# todo: consider using templates for boilerplate network nodes (orderers, peers, ...)
# todo: allow the user to specify the chaincode name (hardcoded as 'basic') both in install and invoke/query
# todo: track down a nasty bug whereby the CA service endpoints (kube services) will occasionally reject TCP connections after network down/up.  This is patched by introducing a 10s sleep after the deployments are up...
# todo: refactor query/invoke to specify chaincode name (-n param)

FABRIC_VERSION=${TEST_NETWORK_FABRIC_VERSION:-2.3.2}
FABRIC_CA_VERSION=${TEST_NETWORK_FABRIC_CA_VERSION:-1.5.2}
FABRIC_CONTAINER_REGISTRY=${TEST_NETWORK_FABRIC_CONTAINER_REGISTRY:-hyperledger}
NETWORK_NAME=${TEST_NETWORK_NAME:-test-network}
CLUSTER_NAME=${TEST_NETWORK_KIND_CLUSTER_NAME:-kind}
NS=${TEST_NETWORK_KUBE_NAMESPACE:-${NETWORK_NAME}}
CHANNEL_NAME=${TEST_NETWORK_CHANNEL_NAME:-mychannel}
CHANNEL_NAME1=${TEST_NETWORK_CHANNEL_NAME:-org1org2channel}
LOG_FILE=${TEST_NETWORK_LOG_FILE:-network.log}
DEBUG_FILE=${TEST_NETWORK_DEBUG_FILE:-network-debug.log}
LOCAL_REGISTRY_NAME=${TEST_NETWORK_LOCAL_REGISTRY_NAME:-kind-registry}
LOCAL_REGISTRY_PORT=${TEST_NETWORK_LOCAL_REGISTRY_PORT:-5000}
NGINX_HTTP_PORT=${TEST_NETWORK_INGRESS_HTTP_PORT:-80}
NGINX_HTTPS_PORT=${TEST_NETWORK_INGRESS_HTTPS_PORT:-443}
CHAINCODE_NAME=${TEST_NETWORK_CHAINCODE_NAME:-asset-transfer-basic}
CHAINCODE_IMAGE=${TEST_NETWORK_CHAINCODE_IMAGE:-ghcr.io/hyperledgendary/fabric-ccaas-asset-transfer-basic}
CHAINCODE_LABEL=${TEST_NETWORK_CHAINCODE_LABEL:-basic_1.0}
PROFILE=${TEST_NETWORK_PROFILE_NAME:-ThreeOrgsApplicationGenesis}
PROFILE1=${TEST_NETWORK_PROFILE_NAME:-Org1Org2ApplicationGenesis}

# todo: more complicated config, as these bleed into the yaml descriptors (sed? kustomize? helm (no)? tkn? ansible?...) or other script locations
TLSADMIN_AUTH=tlsadmin:tlsadminpw
RCAADMIN_AUTH=rcaadmin:rcaadminpw

function print_help() {
  echo todo: help output, parse mode, flags, env, etc.
}

. scripts/utils.sh
. scripts/prereqs.sh
. scripts/kind.sh
. scripts/fabric_config.sh
. scripts/fabric_CAs.sh
. scripts/test_network.sh
. scripts/channel.sh
. scripts/chaincode.sh
. scripts/rest_sample.sh
. scripts/application_connection.sh

# check for kind, kubectl, etc.
check_prereqs

## Parse mode
if [[ $# -lt 1 ]] ; then
  print_help
  exit 0
else
  MODE=$1
  shift
fi

# Initialize the logging system - control output to 'network.log' and everything else to 'network-debug.log'
logging_init

if [ "${MODE}" == "kind" ]; then
  log "Initializing KIND cluster \"${CLUSTER_NAME}\":"
  kind_init
  log "🏁 - Cluster is ready."

elif [ "${MODE}" == "unkind" ]; then
  log "Deleting cluster \"${CLUSTER_NAME}\":"
  kind_unkind
  log "🏁 - Cluster is gone."

elif [ "${MODE}" == "up" ]; then
  log "Launching network \"${NETWORK_NAME}\":"
  network_up
  log "🏁 - Network is ready."

elif [ "${MODE}" == "down" ]; then
  log "Shutting down test network  \"${NETWORK_NAME}\":"
  network_down
  log "🏁 - Fabric network is down."

elif [ "${MODE}" == "channel" ]; then
  ACTION=$1
  shift

  if [ "${ACTION}" == "create" ]; then
    log "Creating channel \"${CHANNEL_NAME}\":"
    channel_up
    log "🏁 - Channel is ready."
    # log "Creating channel \"${CHANNEL_NAME1}\":"
    # channel_up1
    # log "🏁 - Channel is ready."

  else
    print_help
    exit 1
  fi

elif [ "${MODE}" == "chaincode" ]; then
  ACTION=$1
  shift

  if [ "${ACTION}" == "deploy" ]; then
    log "Deploying chaincode \"${CHAINCODE_NAME}\":"
    deploy_chaincode
    log "🏁 - Chaincode is ready."

  elif [ "${ACTION}" == "install" ]; then
    log "Installing chaincode \"${CHAINCODE_NAME}\":"
    install_chaincode
    log "🏁 - Chaincode is installed with CHAINCODE_ID=${CHAINCODE_ID}"

  elif [ "${ACTION}" == "activate" ]; then
    log "Activating chaincode \"${CHAINCODE_NAME}\":"
    activate_chaincode
    log "🏁 - Chaincode is activated with CHAINCODE_ID=${CHAINCODE_ID}"

  elif [ "${ACTION}" == "invoke" ]; then
    invoke_chaincode $@ 2>> ${LOG_FILE}

  elif [ "${ACTION}" == "query" ]; then
    query_chaincode org1 $@ >> ${LOG_FILE}
    query_chaincode org2 $@ >> ${LOG_FILE}
    query_chaincode org3 $@ >> ${LOG_FILE}
    # query_chaincode1 $@ >> ${LOG_FILE}
  
  elif [ "${ACTION}" == "metadata" ]; then
    query_chaincode_metadata >> ${LOG_FILE}
  else
    print_help
    exit 1
  fi

elif [ "${MODE}" == "anchor" ]; then
  update_anchor_peers $@

elif [ "${MODE}" == "rest-easy" ]; then
  log "Launching fabric-rest-sample application:"
  launch_rest_sample
  log "🏁 - Fabric REST sample is ready."

elif [ "${MODE}" == "application" ]; then
  log "Getting application connection information:"
  application_connection
  log "🏁 - Output in...xxx"

else
  print_help
  exit 1
fi

