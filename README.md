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
## Prerequisite steps requiring cluster administrator rights
1. Login with OpenShift cli
```shell
oc login 
```
2. Clone repo to the client workstation or download as a zip from git.
```shell
git clone -b v531 https://github.com/ekleinso/cpd-silent-install.git
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
5. Create service account in **PROJECT_CPD_INST_OPERANDS**
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f service-account.yaml
```
6. Create roles for service account to managed Cloud Pak for Data Resources - https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-authorizing-instance-administrator
```shell
oc apply -n ${PROJECT_CPD_INST_OPERANDS} -f cpd-instance-admin.5.3.1.yaml -f cpd-instance-crs.5.3.1.yaml  -f nss-managed-role.5.3.1.yaml
oc apply -n ${PROJECT_CPD_INST_OPERATORS} -f cpd-instance-admin.5.3.1.yaml -f cpd-instance-crs.5.3.1.yaml  -f nss-managed-role.5.3.1.yaml -f cpd-instance-admin-apply-olm.yaml
oc apply -n ${PROJECT_LICENSE_SERVICE} -f cpd-instance-admin.5.3.1.yaml -f cpd-instance-crs.5.3.1.yaml  -f nss-managed-role.5.3.1.yaml
oc apply -n ${PROJECT_SCHEDULING_SERVICE} -f cpd-instance-admin.5.3.1.yaml -f cpd-instance-crs.5.3.1.yaml  -f nss-managed-role.5.3.1.yaml
oc apply -f cpd-licensemanager-roles.yaml
```
6. Create role bindings for service account
```shell
envsubst < rolebindings.yaml | oc create -f -
ROLE=cpd-instance-admin.5.3.1 envsubst < cpd-rolebindings.yaml | oc create -f -
ROLE=cpd-instance-crs.5.3.1 envsubst < cpd-rolebindings.yaml | oc create -f -
ROLE=nss-managed-role.5.3.1 envsubst < cpd-rolebindings.yaml | oc create -f -
```
7. Add cluster scoped custom resource definitions 
- [Scheduler](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cluster-creating-scoped-resources-shared-components) 
- [CPD Components](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-creating-cluster-scoped-resources)
```shell
oc apply -f scheduler-cluster_scoped_resources.yaml --server-side --force-conflicts 
oc apply -f cluster_scoped_resources.yaml --server-side --force-conflicts 
```
## Installation Notes
1. Login with OpenShift cli
```shell
oc login 
```
2. Clone repo to the client workstation or download as a zip from git.
```shell
git clone -b v531 https://github.com/ekleinso/cpd-silent-install.git
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
5. Update variables in **configmap-vars.yaml** for your environment. For internal repo **IMAGE_PULL_PREFIX** would be something like *registry.example.local/docker* 
```shell
export STG_CLASS_BLOCK="managed-nfs-storage"
export STG_CLASS_FILE="managed-nfs-storage"
export COMPONENTS="cpd_platform,factsheet,analyticsengine,datarefinery,datastage_ent,dmc,wkc,ws_pipelines,wml,openscale,ws,hee,dv"
export ENTITLEMENT_PRODUCTION="false"
export ENTITLEMENT="cpd-enterprise" 
export IMAGE_PULL_PREFIX="icr.io"
export IBM_ENTITLEMENT_KEY="<your entitlement key>"
# or for private registry
export PRIVATE_REGISTRY_USER="<your private registry user>"
export PRIVATE_REGISTRY_PASSWORD="<your private registry password>"

envsubst < configmap-vars.yaml | oc apply -n ${PROJECT_CPD_INST_OPERANDS} -f -

oc apply -n ${PROJECT_CPD_INST_OPERANDS} -f configmap.yaml
```
8. Update value for ***storageClassName*** in all of the entries in **storage.yaml**.
```shell
envsubst < storage.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
9. Create configmaps. Installation scripts/options are in **configmap.yaml** update for you implementation
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f configmap.yaml
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
10. Create secrets
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f secret.yaml
```
11. Update ***spec.containers[0].image*** in **1-pod-shared.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke install of shared components for Cloud Pak for Data.
```shell
envsubst < 1-pod-shared.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
12. Monitor install log and/or check pod status until it is completed
```shell
oc logs -n ${PROJECT_CPD_INST_OPERANDS} -f -l app=cpd-shared
```
or 
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get po -l app=cpd-shared
```
13. Update ***spec.containers[0].image*** in **2-pod-cpd.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke Cloud Pak for Data install
```shell
envsubst < 2-pod-cpd.yaml | oc create -n ${PROJECT_CPD_INST_OPERANDS} -f -
```
14. Monitor install log and/or check pod status until it is completed
```shell
oc logs -n ${PROJECT_CPD_INST_OPERANDS} -f -l app=cpd-install
```
or 
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get po -l app=cpd-install
```
