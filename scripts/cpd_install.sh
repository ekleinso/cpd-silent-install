#!/bin/bash
set -ex
################################################################################
# Login to OCP
################################################################################
login-to-ocp --token=${OCP_TOKEN} --server=${OCP_URL}
################################################################################
# Configure MCG
################################################################################
export NOOBAA_ACCOUNT_CREDENTIALS_SECRET=noobaa-admin
export NOOBAA_ACCOUNT_CERTIFICATE_SECRET=noobaa-s3-serving-cert
setup-mcg --components=watson_assistant --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --noobaa_account_secret=${NOOBAA_ACCOUNT_CREDENTIALS_SECRET} --noobaa_cert_secret=${NOOBAA_ACCOUNT_CERTIFICATE_SECRET}
setup-mcg --components=watsonx_orchestrate --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --noobaa_account_secret=${NOOBAA_ACCOUNT_CREDENTIALS_SECRET} --noobaa_cert_secret=${NOOBAA_ACCOUNT_CERTIFICATE_SECRET}
################################################################################
# Deploy knative
################################################################################
deploy-events-operator --release=${VERSION} --cluster_resources=true
oc apply -f cpd-cli-workspace/olm-utils-workspace/work/ibm-events-operator-crds.yaml --server-side --force-conflicts
deploy-knative-eventing --release=${VERSION} --block_storage_class=${STG_CLASS_BLOCK}
################################################################################
# Install Cloud Pak for Data
################################################################################
case-download --components=${COMPONENTS} --release=${VERSION} --operator_ns=${PROJECT_CPD_INST_OPERATORS} --cluster_resources=true
oc apply -f /tmp/work/cluster_scoped_resources.yaml --server-side --force-conflicts | tee /tmp/work/cluster_scoped_resources.out
authorize-instance-topology --cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
install-components --license_acceptance=true --components=${COMPONENTS} --release=${VERSION} --operator_ns=${PROJECT_CPD_INST_OPERATORS} --instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --image_pull_prefix=${IMAGE_PULL_PREFIX} --image_pull_secret=${IMAGE_PULL_SECRET} --param-file=/tmp/work/install-options.yml
apply-entitlement --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --entitlement=${ENTITLEMENT:-cpd-enterprise} --production=${ENTITLEMENT_PRODUCTION:-false}
get-cpd-instance-details --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --get_admin_initial_credentials=true
