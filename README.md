# IBM Cloud Pak for Data Silent Installation 
This repository contains a framework to perform a silent installation of IBM Cloud Pak for Data on OpenShift. It was developed to replace the need for a bastion and streamline the installation process. As a framework it is not a complete automated solution for installing CPD like [cloud-pak-deployer](https://github.com/IBM/cloud-pak-deployer) or the new [Gitops method leveraging ArgoCD](https://github.com/IBM/cpd-cli/blob/master/docs/argocd/argocd-install.md). It is a starting point for a deployment pipeline that leverages the same tools used for [cpd-cli](https://github.com/IBM/cpd-cli/) installation method. It was created with air-gapped environments in mind but should work in non-air-gapped environments. 

Additional pods can be configured to run additional scripts to perform functions such as adding/removing services, updating certificates, etc by adding scripts to the cpd-install-options ConfigMap and creating a new pod using the 2-pod-cpd.yaml file as an example.

## OpenShift Prerequisites
- (Required) [Red Hat OpenShift cert-manager Operator](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cluster-installing-cert-manager-operator)
- (Optional) [GPU Operators](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=software-installing-operators-services-that-require-gpus)
- (Optional) [Red Hat OpenShift AI](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=software-installing-red-hat-openshift-ai)
- (Optional) [Red Hat OpenShift Serverless Knative Eventing](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=software-installing-red-hat-openshift-serverless-knative-eventing)

Check the documentation links to determine if you need the optional components for the services you plan to install.
These prerequisites and other manual steps such as mirroring images for air-gapped environments are not automated here because in most environments they may already installed or are managed by other teams.
## Installation Notes
1. Login with OpenShift cli
```shell
oc login 
```
2. Clone repo to the client workstation or download as a zip from git.
```shell
git clone -b v531-1ez https://github.com/ekleinso/cpd-silent-install.git
```
3. Change into directory ***cpd-silent-install***.
```shell
cd cpd-silent-install
```
4. Make sure the 4 projects are created in OpenShift

| Cloud Pak Service | Project Name |
| :---------------------- | :------------ |
| PROJECT_LICENSE_SERVICE | ibm-licensing |
| PROJECT_SCHEDULING_SERVICE | ibm-scheduler |
| PROJECT_CPD_INST_OPERATORS | ibm-operators |
| PROJECT_CPD_INST_OPERANDS | ibm-instance |

```shell
export PROJECT_LICENSE_SERVICE="ibm-licensing"
export PROJECT_SCHEDULING_SERVICE="ibm-scheduler"
export PROJECT_CPD_INST_OPERATORS="ibm-operators"
export PROJECT_CPD_INST_OPERANDS="ibm-instance"
```
(Optional) If resource quotas are configured either delete them or make sure they are increased for CP4D
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} cm cpd-silent-quotas --from-literal=quotas="$(envsubst < resourcequota.yaml)" 
```
(Optional) If resource quotas are configured we will need to configure limitranges that will configure default limits for pods that may not be configured with limits
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} cm cpd-silent-limitranges --from-literal=limitranges="$(envsubst < limitranges.yaml)" 
```
(Optional) If NetworkPolicy is configured for the project either delete them or make sure they are configured for CP4D
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} cm cpd-silent-networkpolicy --from-literal=networkpolicy="$(envsubst < networkpolicy.yaml)"
```
5. Create service account in **PROJECT_CPD_INST_OPERANDS**
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f service-account.yaml
```
6. Create role bindings for service account
```shell
envsubst < rolebindings.yaml | oc create -f -
```
7. Update variables in **configmap.yaml** for your environment. For internal repo **IMAGE_PULL_PREFIX** would be something like *registry.example.local/docker* 
```shell
export STG_CLASS_BLOCK="managed-nfs-storage"
export STG_CLASS_FILE="managed-nfs-storage"
export COMPONENTS="cpd_platform,watsonx_orchestrate"
export ENTITLEMENT_PRODUCTION="false"
export ENTITLEMENT="watsonx-orchestrate" 
export IMAGE_PULL_PREFIX="icr.io"
export IBM_ENTITLEMENT_KEY="<your entitlement key>"
# or for private registry
export PRIVATE_REGISTRY_USER="<your private registry user>"
export PRIVATE_REGISTRY_PASSWORD="<your private registry password>"

envsubst < configmap.yaml | oc apply -f -
```
8. Update value for ***storageClassName*** in all of the entries in **storage.yaml**.
```shell
envsubst < storage.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
9. Modify installation scripts/options found in the scripts directory for you implementation requirements then create ConfigMap
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} cm cpd-install-options \
--from-file=install-options.yml=scripts/install-options.yml \
--from-file=cpd_shared.sh=scripts/cpd_shared.sh \
--from-file=cpd_install.sh=scripts/cpd_install.sh
```
10. Create ConfigMaps for the case file
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-00.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-01.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-02.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-03.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-04.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-05.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-06.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-07.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-08.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-09.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-10.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-11.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-12.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-13.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-14.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-15.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-16.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-17.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-18.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-19.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-20.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-21.yaml
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f case-22.yaml
```
11. Create secrets
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f secret.yaml
```
12. Update ***spec.containers[0].image*** in **1-cpd-shared.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke install of shared components for Cloud Pak for Data.
```shell
envsubst < 1-cpd-shared.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
13. Monitor install log and/or check pod status until it is completed
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} logs -f job.batch/cpd-shared-v53x 
```
or 
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get job -l app=cpd-shared -w
```
14. (Optional) If pod completes successfully it is safe to cleanup *case-* ConfigMaps
```shell
oc delete -n ${PROJECT_CPD_INST_OPERANDS} ConfigMap case-00 case-01 case-02 case-03 case-04 case-05 case-06 case-07 case-08 case-09 case-10 case-11 case-12 case-13 case-14 case-15 case-16 case-17 case-18 case-19 case-20 case-21 case-22
```
15. Update ***spec.containers[0].image*** in **2-cpd-install.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke Cloud Pak for Data install
```shell
envsubst < 2-cpd-install.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
16. Monitor job status until it is completed
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get job -l app=cpd-install -w
```
or
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} logs -f job.batch/cpd-install-v53x 
```