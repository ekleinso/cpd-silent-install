#!/bin/bash
set -ex
################################################################################
# Login to OCP
################################################################################
login-to-ocp --token=${OCP_TOKEN} --server=${OCP_URL}
install-cpd-config-ac --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
enable-cpd-config-ac --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
oc -n openshift-config get cm user-ca-bundle -o jsonpath='{.data.ca-bundle\.crt}' > /tmp/work/ca-bundle.crt
oc create secret generic cpd-custom-ca-certs -n ${PROJECT_CPD_INST_OPERANDS} --from-file=ca-bundle.crt=/tmp/work/ca-bundle.crt
gen-platform-ca-certs --cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} --apply=true
