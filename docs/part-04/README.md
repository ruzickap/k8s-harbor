# Install Harbor

![Harbor logo](https://raw.githubusercontent.com/cncf/artwork/c33a8386bce4eabc36e1d4972e0996db4630037b/projects/harbor/horizontal/color/harbor-horizontal-color.svg?sanitize=true
"Harbor logo")

## Install Harbor using Argo CD

Login to Argo CD:

```bash
argocd login --insecure argocd-grpc.${MY_DOMAIN} --username admin --password admin
```

Output:

```text
'admin' logged in successfully
Context 'argocd-grpc.mylabs.dev' updated
```

Create new `harbor` project:

```bash
argocd --server argocd-grpc.${MY_DOMAIN} proj create harbor --description "Harbor project" --dest https://kubernetes.default.svc,harbor-system --src https://github.com/goharbor/harbor-helm.git
```

Create namespace for Harbor and copy there the secrets with Let's encrypt
certificate:

```bash
kubectl create namespace harbor-system
kubectl label namespace harbor-system app=kubed
```

Deploy Harbor:

```bash
argocd --server argocd-grpc.${MY_DOMAIN} app create harbor \
  --auto-prune \
  --dest-namespace harbor-system \
  --dest-server https://kubernetes.default.svc \
  --path . \
  --project harbor \
  --repo https://github.com/goharbor/harbor-helm.git \
  --revision v1.1.0 \
  --sync-policy automated \
  -p database.type=external \
  -p database.external.host=pgsql.${MY_DOMAIN} \
  -p database.external.username=harbor_user \
  -p database.external.password=harbor_user_password \
  -p database.external.coreDatabase=harbor-registry \
  -p database.external.clairDatabase=harbor-clair \
  -p database.external.notaryServerDatabase=harbor-notary_server \
  -p database.external.notarySignerDatabase=harbor-notary_signer \
  -p expose.ingress.hosts.core=core.${MY_DOMAIN} \
  -p expose.ingress.hosts.notary=notary.${MY_DOMAIN} \
  -p expose.tls.secretName=ingress-cert-${LETSENCRYPT_ENVIRONMENT} \
  -p externalURL=https://core.${MY_DOMAIN} \
  -p harborAdminPassword=admin \
  -p persistence.resourcePolicy=delete \
  -p persistence.persistentVolumeClaim.registry.size=1Gi \
  -p persistence.persistentVolumeClaim.chartmuseum.size=1Gi
```

Output:

```text
application 'harbor' created
```

Check the status of the Harbor application and wait until it's fully initialized:

```bash
argocd --server argocd-grpc.${MY_DOMAIN} app wait --health harbor
```

Output:

```text
TIMESTAMP  GROUP        KIND   NAMESPACE                  NAME    STATUS   HEALTH        HOOK  MESSAGE
...
2019-05-27T07:32:40+02:00   apps  Deployment  harbor-system  harbor-harbor-notary-server    Synced  Healthy              deployment.apps/harbor-harbor-notary-server created
2019-05-27T07:32:48+02:00   apps  Deployment  harbor-system  harbor-harbor-chartmuseum    Synced  Healthy              deployment.apps/harbor-harbor-chartmuseum created
2019-05-27T07:32:55+02:00   apps  StatefulSet  harbor-system   harbor-harbor-redis    Synced  Healthy              statefulset.apps/harbor-harbor-redis created
2019-05-27T07:33:04+02:00   apps  Deployment  harbor-system  harbor-harbor-registry    Synced  Healthy              deployment.apps/harbor-harbor-registry created
2019-05-27T07:33:05+02:00   apps  Deployment  harbor-system   harbor-harbor-clair    Synced  Healthy              deployment.apps/harbor-harbor-clair created
2019-05-27T07:34:10+02:00   apps  Deployment  harbor-system    harbor-harbor-core    Synced  Healthy              deployment.apps/harbor-harbor-core created

Name:               harbor
Project:            harbor
Server:             https://kubernetes.default.svc
Namespace:          harbor-system
URL:                https://argocd-grpc.mylabs.dev/applications/harbor
Repo:               https://github.com/goharbor/harbor-helm.git
Target:             v1.1.0
Path:               .
Sync Policy:        Automated (Prune)
Sync Status:        Synced to v1.1.0 (223528d)
Health Status:      Healthy


GROUP       KIND                   NAMESPACE      NAME                         STATUS  HEALTH
            ConfigMap              harbor-system  harbor-harbor-chartmuseum    Synced  Healthy
            Service                harbor-system  harbor-harbor-core           Synced  Healthy
            Service                harbor-system  harbor-harbor-notary-signer  Synced  Healthy
            Service                harbor-system  harbor-harbor-redis          Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-portal         Synced  Healthy
            Secret                 harbor-system  harbor-harbor-registry       Synced  Healthy
            PersistentVolumeClaim  harbor-system  harbor-harbor-chartmuseum    Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-registry       Synced  Healthy
            ConfigMap              harbor-system  harbor-harbor-clair          Synced  Healthy
            Service                harbor-system  harbor-harbor-notary-server  Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-jobservice     Synced  Healthy
            PersistentVolumeClaim  harbor-system  harbor-harbor-jobservice     Synced  Healthy
            Service                harbor-system  harbor-harbor-clair          Synced  Healthy
            Service                harbor-system  harbor-harbor-jobservice     Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-notary-server  Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-notary-signer  Synced  Healthy
extensions  Ingress                harbor-system  harbor-harbor-ingress        Synced  Healthy
            Secret                 harbor-system  harbor-harbor-chartmuseum    Synced  Healthy
            ConfigMap              harbor-system  harbor-harbor-notary-server  Synced  Healthy
            ConfigMap              harbor-system  harbor-harbor-registry       Synced  Healthy
            PersistentVolumeClaim  harbor-system  harbor-harbor-registry       Synced  Healthy
            Service                harbor-system  harbor-harbor-chartmuseum    Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-chartmuseum    Synced  Healthy
            Secret                 harbor-system  harbor-harbor-core           Synced  Healthy
            Service                harbor-system  harbor-harbor-registry       Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-clair          Synced  Healthy
apps        Deployment             harbor-system  harbor-harbor-core           Synced  Healthy
apps        StatefulSet            harbor-system  harbor-harbor-redis          Synced  Healthy
            Secret                 harbor-system  harbor-harbor-jobservice     Synced  Healthy
            ConfigMap              harbor-system  harbor-harbor-core           Synced  Healthy
            ConfigMap              harbor-system  harbor-harbor-jobservice     Synced  Healthy
            Service                harbor-system  harbor-harbor-portal         Synced  Healthy
```

Harbor architecture:

![Harbor Architecture](https://raw.githubusercontent.com/goharbor/harbor/5d31dd5b57d83f300907744aabf13ca60aac19b3/docs/img/harbor-arch.png
"Harbor Architecture")

Check how the Harbor Ingress looks like:

```bash
kubectl describe ingresses -n harbor-system harbor-harbor-ingress
```

Output:

```text
Name:             harbor-harbor-ingress
Namespace:        harbor-system
Address:          3.122.97.63
Default backend:  default-http-backend:80 (<none>)
TLS:
  ingress-cert-production terminates core.mylabs.dev
  ingress-cert-production terminates notary.mylabs.dev
Rules:
  Host               Path  Backends
  ----               ----  --------
  core.mylabs.dev
                     /             harbor-harbor-portal:80 (192.168.23.107:80)
                     /api/         harbor-harbor-core:80 (192.168.1.163:8080)
                     /service/     harbor-harbor-core:80 (192.168.1.163:8080)
                     /v2/          harbor-harbor-core:80 (192.168.1.163:8080)
                     /chartrepo/   harbor-harbor-core:80 (192.168.1.163:8080)
                     /c/           harbor-harbor-core:80 (192.168.1.163:8080)
  notary.mylabs.dev
                     /   harbor-harbor-notary-server:4443 (192.168.52.129:4443)
Annotations:
  ingress.kubernetes.io/proxy-body-size:             0
  ingress.kubernetes.io/ssl-redirect:                true
  kubectl.kubernetes.io/last-applied-configuration:  {"apiVersion":"extensions/v1beta1","kind":"Ingress","metadata":{"annotations":{"ingress.kubernetes.io/proxy-body-size":"0","ingress.kubernetes.io/ssl-redirect":"true","nginx.ingress.kubernetes.io/proxy-body-size":"0","nginx.ingress.kubernetes.io/ssl-redirect":"true"},"labels":{"app":"harbor","app.kubernetes.io/instance":"harbor","chart":"harbor","heritage":"Tiller","release":"harbor"},"name":"harbor-harbor-ingress","namespace":"harbor-system"},"spec":{"rules":[{"host":"core.mylabs.dev","http":{"paths":[{"backend":{"serviceName":"harbor-harbor-portal","servicePort":80},"path":"/"},{"backend":{"serviceName":"harbor-harbor-core","servicePort":80},"path":"/api/"},{"backend":{"serviceName":"harbor-harbor-core","servicePort":80},"path":"/service/"},{"backend":{"serviceName":"harbor-harbor-core","servicePort":80},"path":"/v2/"},{"backend":{"serviceName":"harbor-harbor-core","servicePort":80},"path":"/chartrepo/"},{"backend":{"serviceName":"harbor-harbor-core","servicePort":80},"path":"/c/"}]}},{"host":"notary.mylabs.dev","http":{"paths":[{"backend":{"serviceName":"harbor-harbor-notary-server","servicePort":4443},"path":"/"}]}}],"tls":[{"hosts":["core.mylabs.dev"],"secretName":"ingress-cert-production"},{"hosts":["notary.mylabs.dev"],"secretName":"ingress-cert-production"}]}}

  nginx.ingress.kubernetes.io/proxy-body-size:  0
  nginx.ingress.kubernetes.io/ssl-redirect:     true
Events:
  Type    Reason  Age    From                      Message
  ----    ------  ----   ----                      -------
  Normal  CREATE  3m27s  nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
  Normal  UPDATE  3m15s  nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
```

Open the [https://core.mylabs.dev](https://core.mylabs.dev):

![Harbor login page](./harbor_login_page.png "Harbor login page")

Log in:

* User: `admin`
* Password: `admin`

You should see the Web UI:

![Harbor](./harbor_projects.png "Harbor")
