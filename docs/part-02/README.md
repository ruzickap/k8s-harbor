# Install Helm

Install [Helm](https://helm.sh/) binary:

```bash
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- --version v2.16.1
```

Output:

```text
Helm v2.16.1 is already v2.16.1
Run 'helm init' to configure helm.
```

Install Tiller (the Helm server-side component) into the Kubernetes cluster:

```bash
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --wait --service-account tiller
```

Output:

```text
Creating /home/pruzicka/.helm
Creating /home/pruzicka/.helm/repository
Creating /home/pruzicka/.helm/repository/cache
Creating /home/pruzicka/.helm/repository/local
Creating /home/pruzicka/.helm/plugins
Creating /home/pruzicka/.helm/starters
Creating /home/pruzicka/.helm/cache/archive
Creating /home/pruzicka/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /home/pruzicka/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

Check if the tiller was installed properly:

```bash
kubectl get pods -l app=helm -n kube-system
```

Output:

```text
NAME                             READY   STATUS    RESTARTS   AGE
tiller-deploy-845fb7cfc6-k47c2   1/1     Running   0          9s
```

Add [Helm plugin](https://github.com/chartmuseum/helm-push) to push chart
package to [ChartMuseum](https://chartmuseum.com/):

```bash
helm plugin list | grep ^push || helm plugin install https://github.com/chartmuseum/helm-push
```

Output:

```text
Downloading and installing helm-push v0.7.1 ...
https://github.com/chartmuseum/helm-push/releases/download/v0.7.1/helm-push_0.7.1_linux_amd64.tar.gz
Installed plugin: push
```

![Helm Chart Repository](https://raw.githubusercontent.com/helm/chartmuseum/f8b563ea87317eb490eefd51f74d43b0f466d132/logo2.png
"Helm Chart Repository")
