# Install Helm

Helm Architecture:

![Helm Architecture](https://cdn.app.compendium.com/uploads/user/e7c690e8-6ff9-102a-ac6d-e4aebca50425/5a29c3c1-7c6b-41fa-8082-bdc8a36177c9/Image/c64c01d08df64f4420e81f962fd13a23/screen_shot_2018_09_11_at_4_48_19_pm.png
"Helm Architecture")
([https://blogs.oracle.com/cloudnative/helm-kubernetes-package-management](https://blogs.oracle.com/cloudnative/helm-kubernetes-package-management))

Install [Helm](https://helm.sh/) binary:

```bash
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash -s -- --version v2.14.1
```

Output:

```text
Helm v2.14.1 is already v2.14.1
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
tiller-deploy-7b659b7fbd-rwqmr   1/1     Running   0          165m
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
