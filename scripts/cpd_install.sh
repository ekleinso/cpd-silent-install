#!/bin/bash
set -ex
################################################################################
# Login to OCP
################################################################################
login-to-ocp --token=${OCP_TOKEN} --server=${OCP_URL}
################################################################################
# Install Cloud Pak for Data
################################################################################
install-components --license_acceptance=true --components=${COMPONENTS} --release=${VERSION} --operator_ns=${PROJECT_CPD_INST_OPERATORS} --instance_ns=${PROJECT_CPD_INST_OPERANDS} --block_storage_class=${STG_CLASS_BLOCK} --file_storage_class=${STG_CLASS_FILE} --image_pull_prefix=${IMAGE_PULL_PREFIX} --image_pull_secret=${IMAGE_PULL_SECRET} --param-file=/tmp/work/install-options.yml
apply-entitlement --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --entitlement=${ENTITLEMENT:-cpd-enterprise} --production=${ENTITLEMENT_PRODUCTION:-false}
get-cpd-instance-details --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --get_admin_initial_credentials=true
