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
envsubst < resourcequota.yaml | oc apply -f -
```
(Optional) If resource quotas are configured we will need to configure limitranges that will configure default limits for pods that may be configured with limits
```shell
envsubst < limitranges.yaml | oc apply -f -
```
(Optional) If NetworkPolicy is configured for the project either delete them or make sure they are configured for CP4D
```shell
envsubst < networkpolicy.yaml | oc apply -f -
```
5. Create service account in **PROJECT_CPD_INST_OPERANDS**
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f service-account.yaml
```
6. Create role bindings for service account
```shell
envsubst < rolebindings.yaml | oc create -f -
```
7. Update variables in **configmap-vars.yaml** for your environment. For internal repo IMAGE_PULL_PREFIX would be something like *registry.exampe.local/docker*.
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cpd-vars
  namespace: ${PROJECT_CPD_INST_OPERANDS}
data:
  PROJECT_LICENSE_SERVICE: "${PROJECT_LICENSE_SERVICE}"
  PROJECT_SCHEDULING_SERVICE: "${PROJECT_SCHEDULING_SERVICE}"
  PROJECT_CPD_INST_OPERATORS: "${PROJECT_CPD_INST_OPERATORS}"
  PROJECT_CPD_INST_OPERANDS: "${PROJECT_CPD_INST_OPERANDS}"
  OPENSHIFT_TYPE: "self-managed"
  IBM_ENTITLEMENT_KEY: "<your entitlement key>"
  COMPONENTS: "cpd_platform,factsheet,analyticsengine,datarefinery,datastage_ent,dmc,wkc,ws_pipelines,wml,openscale,ws,hee,dv"
  VERSION: "5.3.1"
  IMAGE_ARCH: "amd64"
  STG_CLASS_BLOCK: "managed-nfs-server"
  STG_CLASS_FILE: "managed-nfs-server"
  OCP_URL: "kubernetes.default.svc.cluster.local"
  IMAGE_PULL_SECRET: "ibm-entitlement-key"
  IMAGE_PULL_PREFIX: "icr.io"
  OLM_UTILS_IMAGE: "icr.io/cpopen/cpd/olm-utils-v4@sha256:3f03ae78e4101a63c089980ffb5eef0db51b8897afd44b609ce409897e5f0827"
```

```shell
envsubst < configmap-vars.yaml | oc apply -n ${PROJECT_CPD_INST_OPERANDS} -f -
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f configmap.yaml
```
8. Update value for ***storageClassName*** in all of the entries in **storage.yaml** if you changed the ***STG_CLASS_FILE*** variable in **configmap.yaml** before you run command to create storage.
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f storage.yaml
```
9. Create secrets
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f secret.yaml
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
10. Update ***spec.containers[0].image*** in **1-pod-shared.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke install of shared components for Cloud Pak for Data.
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f 1-pod-shared.yaml
```
11. Monitor install log and/or check pod status until it is completed
```shell
oc logs -n ${PROJECT_CPD_INST_OPERANDS} -f -l app=cpd-shared
```
or 
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get po -l app=cpd-shared
```
12. Update ***spec.containers[0].image*** in **2-pod-cpd.yaml** to point to the correct repository/image as necessary for your environment. Create pod to invoke Cloud Pak for Data install
```shell
oc create -n ${PROJECT_CPD_INST_OPERANDS} -f 2-pod-cpd.yaml
```
13. Monitor install log and/or check pod status until it is completed
```shell
oc logs -n ${PROJECT_CPD_INST_OPERANDS} -f -l app=cpd-install
```
or 
```shell
oc -n ${PROJECT_CPD_INST_OPERANDS} get po -l app=cpd-install
```
