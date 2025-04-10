# Helm ProActive Chart

## Prerequisites

[Helm](https://helm.sh) must be installed to use the Charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

[Kubectl](https://kubernetes.io/docs/reference/kubectl/) must be installed.

An AKS or Baremetal Kubernetes cluster is available.

ProActive Pods pull the Server, Node, and Database images from the [Private Activeeon Docker Registry](https://dockerhub.activeeon.com/).

To be able to pull images from the Private Activeeon Docker Registry, a ProActive enterprise licence and access credentials are required.

Please [contact us](mailto:contact@activeeon.com) to request access before installing the Chart.

## Required Configuration

⚠️ Note that before installing the ProActive Helm Chart, several installation configurations can be set in the `values.yml` file. 

You can use default values; however, the following specific properties must be configured as outlined below:

- The target Kubernetes cluster for the installation must be set in `target.cluster`: `aks` or `on-prem`
- The credentials to pull ProActive Images need to be provided through the `imageCredentials` property
- For an on-prem installation, the Kubernetes Node name to host the Scheduler and Database Pods must be provided in `persistentVolumes.localVolumeConfig.scheduler.persistentVolume.nodeAffinity.nodeName` and `persistentVolumes.localVolumeConfig.database.persistentVolume.nodeAffinity.nodeName` 
- For an on-prem installation, a directory must be created beforehand on the Node defined by the `nodeAffinity` to host the persistent volume's data. The directory absolute path must be given in `persistentVolumes.localVolumeConfig.scheduler.persistentVolume.localPath` and `persistentVolumes.localVolumeConfig.database.persistentVolume.localPath`
- To ensure to have dynamic ProActive Kubernetes nodes after server startup, you need to copy and paste the cluster configuration, for example, from `~/.kube/config`, into the `files/kube.config` file.
- To enable TLS encryption, you must first install or enable the Ingress and Cert Manager controllers in your cluster (refer to the commands below). Next, configure the Ingress and TLS properties in `values.yaml`. Enable the creation of Ingress resources by setting `ingress.enabled` to true. Finally, within the same configuration block, enable and configure one of the three TLS certificates to be used: provided, self-signed, or Let's Encrypt.
```console
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.3/cert-manager.yaml
```

## Installation

Login to the Activeeon Registry where the ProActive Helm Chart is located:

```console
helm registry login dockerhub.activeeon.com
```
Pull the ProActive Helm Chart:

```console
helm pull oci://dockerhub.activeeon.com/helm/activeeon-proactive-chart --version 2.0.0
```
This will download the Helm Chart as a `.tgz` file. Afterward, you can extract it and access its contents.
```console
tar -xvzf activeeon-proactive-chart-2.0.0.tgz
cd activeeon-proactive-chart
```

Finally, you can install it:

```console
helm install pa-helm-chart .
```

## Usage
Using the default configuration, you can access the ProActive Portals for example: 

On on-prem installation:
```console
http://on-prem-cluster-ip-or-dns:32000
```
(32000 is the default NodePort)

On AKS installation:
```console
http://aks-cluster-load-balancer-ip-or-dns:8080
```

## Extra Notes
How to push a helm chart:
```console
helm registry login dockerhub.activeeon.com
helm package .
helm push activeeon-proactive-chart-2.0.0.tgz oci://dockerhub.activeeon.com/helm 
```
How to install the helm chart from a registry url:
```console
helm install pa-helm-chart oci://dockerhub.activeeon.com/helm/activeeon-proactive-chart --version 2.0.0
```
You can use ```--set key1=value1,key2.prop=value2``` to define some properties values to pass to the ```values.yaml``` file.