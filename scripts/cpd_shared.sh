#!/bin/bash
set -ex
cat case.* > /tmp/work/case.tar.gz
tar -C /tmp/work -zxf /tmp/work/case.tar.gz
################################################################################
# Login to OCP
################################################################################
login-to-ocp --token=${OCP_TOKEN} --server=${OCP_URL}
################################################################################
# Process LimitRanges, NetworkPolicy and Quotas
################################################################################
oc get cm cpd-silent-limitranges -o jsonpath='{.data.limitranges}' | tee > /tmp/work/limitranges.yaml
[ -s "/tmp/work/limitranges.yaml" ] && oc apply -f /tmp/work/limitranges.yaml
oc get cm cpd-silent-networkpolicy -o jsonpath='{.data.networkpolicy}' | tee > /tmp/work/networkpolicy.yaml
[ -s "/tmp/work/networkpolicy.yaml" ] && oc apply -f /tmp/work/networkpolicy.yaml
oc get cm cpd-silent-quotas -o jsonpath='{.data.quotas}' | tee > /tmp/work/resourcequota.yaml
[ -s "/tmp/work/resourcequota.yaml" ] && oc apply -f /tmp/work/resourcequota.yaml
################################################################################
# Configure pull secrets
################################################################################
if [ "${IMAGE_PULL_PREFIX}" == "icr.io" ]; then
  if [ -z "${IBM_ENTITLEMENT_KEY}" ]; then
    echo "You must configure an IBM_ENTITLEMENT_KEY"
    exit 1
  else
    IMAGE_PULL_CREDENTIALS=$(echo -n "cp:${IBM_ENTITLEMENT_KEY}" | base64 -w 0)
    cat <<EOF > /tmp/work/dockerconfig.json 
{"auths": {"cp.icr.io": {"auth": "${IMAGE_PULL_CREDENTIALS}"},"icr.io":{"auth": "${IMAGE_PULL_CREDENTIALS}"}}}
EOF
  fi
else
  if [ -z "${PRIVATE_REGISTRY_USER}" ] && [ -z "${PRIVATE_REGISTRY_PASSWORD}" ]; then
      IMAGE_PULL_CREDENTIALS=$(echo -n "using_global:using_global" | base64 -w 0)
      cat <<EOF > /tmp/work/dockerconfig.json 
{"auths": {"using_global": {"auth": "${IMAGE_PULL_CREDENTIALS}"}}}
EOF
  else
    if [ "${PRIVATE_REGISTRY_USER}" == "global" ]; then
      IMAGE_PULL_CREDENTIALS=$(echo -n "using_global:using_global" | base64 -w 0)
      cat <<EOF > /tmp/work/dockerconfig.json 
{"auths": {"using_global": {"auth": "${IMAGE_PULL_CREDENTIALS}"}}}
EOF
    else
      IMAGE_PULL_CREDENTIALS=$(echo -n "${PRIVATE_REGISTRY_USER}:${PRIVATE_REGISTRY_PASSWORD}" | base64 -w 0)
      cat <<EOF > /tmp/work/dockerconfig.json 
{"auths": {"${IMAGE_PULL_PREFIX%/*}": {"auth": "${IMAGE_PULL_CREDENTIALS}"}}}
EOF
    fi
  fi
fi
oc create secret docker-registry ${IMAGE_PULL_SECRET} --from-file=".dockerconfigjson=/tmp/work/dockerconfig.json" --namespace=${PROJECT_SCHEDULING_SERVICE}
oc create secret docker-registry ${IMAGE_PULL_SECRET} --from-file=".dockerconfigjson=/tmp/work/dockerconfig.json" --namespace=${PROJECT_CPD_INST_OPERATORS}
oc create secret docker-registry ${IMAGE_PULL_SECRET} --from-file=".dockerconfigjson=/tmp/work/dockerconfig.json" --namespace=${PROJECT_CPD_INST_OPERANDS}
################################################################################
# Install License Manager and Scheduler
################################################################################
apply-cluster-components --release=${VERSION} --license_acceptance=true --licensing_ns=${PROJECT_LICENSE_SERVICE}
apply-scheduler --release=${VERSION} --license_acceptance=true --scheduler_ns=${PROJECT_SCHEDULING_SERVICE} --image_pull_prefix=${IMAGE_PULL_PREFIX} --image_pull_secret=${IMAGE_PULL_SECRET}
