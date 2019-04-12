# Install Harbor

Generate certificate:

```bash
kubectl create namespace harbor-system
envsubst < files/cert-manager-letsencrypt-aws-route53-certificate.yaml | kubectl apply -f -
cat files/cert-manager-letsencrypt-aws-route53-certificate.yaml
```

Output:

```text
namespace/harbor-system created
certificate.certmanager.k8s.io/ingress-cert-staging created
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  namespace: harbor-system
spec:
  secretName: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-${LETSENCRYPT_ENVIRONMENT}-dns
  commonName: "*.${MY_DOMAIN}"
  dnsNames:
  - "*.${MY_DOMAIN}"
  - ${MY_DOMAIN}
  acme:
    config:
    - dns01:
        provider: aws-route53
      domains:
      - "*.${MY_DOMAIN}"
      - ${MY_DOMAIN}
```

You should see the following output form cert-manager:

```bash
kubectl describe certificates ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n harbor-system
```

Output

```text
Name:         ingress-cert-staging
Namespace:    harbor-system
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"ingress-cert-staging","namespace":"h...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2019-04-12T07:06:44Z
  Generation:          1
  Resource Version:    14320
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/harbor-system/certificates/ingress-cert-staging
  UID:                 87f89871-5cf1-11e9-9a4a-0ab920a68c36
Spec:
  Acme:
    Config:
      Dns 01:
        Provider:  aws-route53
      Domains:
        *.mylabs.dev
        mylabs.dev
  Common Name:  *.mylabs.dev
  Dns Names:
    *.mylabs.dev
    mylabs.dev
  Issuer Ref:
    Kind:       ClusterIssuer
    Name:       letsencrypt-staging-dns
  Secret Name:  ingress-cert-staging
Status:
  Conditions:
    Last Transition Time:  2019-04-12T07:10:35Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2019-07-11T06:10:33Z
Events:
  Type    Reason         Age    From          Message
  ----    ------         ----   ----          -------
  Normal  Generated      4m28s  cert-manager  Generated new private key
  Normal  OrderCreated   4m28s  cert-manager  Created Order resource "ingress-cert-staging-3500457514"
  Normal  OrderComplete  38s    cert-manager  Order "ingress-cert-staging-3500457514" completed successfully
  Normal  CertIssued     38s    cert-manager  Certificate issued successfully
```

The Kubernetes `secret` should contain the certificates:

```bash
kubectl describe secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n harbor-system
```

Output:

```text
Name:         ingress-cert-staging
Namespace:    harbor-system
Labels:       certmanager.k8s.io/certificate-name=ingress-cert-staging
Annotations:  certmanager.k8s.io/alt-names: *.mylabs.dev,mylabs.dev
              certmanager.k8s.io/common-name: *.mylabs.dev
              certmanager.k8s.io/issuer-kind: ClusterIssuer
              certmanager.k8s.io/issuer-name: letsencrypt-staging-dns

Type:  kubernetes.io/tls

Data
====
ca.crt:   0 bytes
tls.crt:  3558 bytes
tls.key:  1679 bytes
```

Clone the repository with Harbor Helm Charts:

```bash
test -d tmp || mkdir tmp
cd tmp
git clone https://github.com/goharbor/harbor-helm
cd harbor-helm
git checkout 1.0.1
```

Install Harbor using Helm:

```bash
helm install --wait --name harbor --namespace harbor-system . \
  --set expose.ingress.hosts.core=core.${MY_DOMAIN} \
  --set expose.ingress.hosts.notary=notary.${MY_DOMAIN} \
  --set expose.tls.secretName=ingress-cert-${LETSENCRYPT_ENVIRONMENT} \
  --set persistence.enabled=false \
  --set externalURL=https://core.${MY_DOMAIN} \
  --set harborAdminPassword=admin
```

Output:

```text
NAME:   harbor
LAST DEPLOYED: Fri Apr 12 09:12:12 2019
NAMESPACE: harbor-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                         DATA  AGE
harbor-harbor-adminserver    39    2m7s
harbor-harbor-chartmuseum    24    2m7s
harbor-harbor-clair          1     2m7s
harbor-harbor-core           1     2m7s
harbor-harbor-jobservice     1     2m7s
harbor-harbor-notary-server  5     2m7s
harbor-harbor-registry       2     2m7s

==> v1/Deployment
NAME                         READY  UP-TO-DATE  AVAILABLE  AGE
harbor-harbor-adminserver    1/1    1           1          2m7s
harbor-harbor-chartmuseum    1/1    1           1          2m7s
harbor-harbor-clair          1/1    1           1          2m7s
harbor-harbor-core           1/1    1           1          2m7s
harbor-harbor-jobservice     1/1    1           1          2m7s
harbor-harbor-notary-server  1/1    1           1          2m7s
harbor-harbor-notary-signer  1/1    1           1          2m7s
harbor-harbor-portal         1/1    1           1          2m7s
harbor-harbor-registry       1/1    1           1          2m7s

==> v1/Pod(related)
NAME                                          READY  STATUS   RESTARTS  AGE
harbor-harbor-adminserver-77948f97dc-jkqnm    1/1    Running  0         2m7s
harbor-harbor-chartmuseum-79c67b57d4-8zj8s    1/1    Running  0         2m7s
harbor-harbor-clair-66c4947d5b-ghgbk          1/1    Running  1         2m7s
harbor-harbor-core-7454f4cfd4-6l8ws           1/1    Running  0         2m7s
harbor-harbor-database-0                      1/1    Running  0         2m7s
harbor-harbor-jobservice-784cfb6586-t89dj     1/1    Running  0         2m7s
harbor-harbor-notary-server-986f5cf9d-mpqcl   1/1    Running  1         2m7s
harbor-harbor-notary-signer-6477c86486-5d9xs  1/1    Running  1         2m7s
harbor-harbor-portal-86458876fd-dg6tr         1/1    Running  0         2m6s
harbor-harbor-redis-0                         1/1    Running  0         2m7s
harbor-harbor-registry-7b69c8cb6-jcjxn        2/2    Running  0         2m6s

==> v1/Secret
NAME                       TYPE    DATA  AGE
harbor-harbor-adminserver  Opaque  4     2m7s
harbor-harbor-chartmuseum  Opaque  1     2m7s
harbor-harbor-core         Opaque  4     2m7s
harbor-harbor-database     Opaque  1     2m7s
harbor-harbor-jobservice   Opaque  1     2m7s
harbor-harbor-registry     Opaque  1     2m7s

==> v1/Service
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
harbor-harbor-adminserver    ClusterIP  10.100.204.195  <none>       80/TCP             2m7s
harbor-harbor-chartmuseum    ClusterIP  10.100.30.159   <none>       80/TCP             2m7s
harbor-harbor-clair          ClusterIP  10.100.63.103   <none>       6060/TCP           2m7s
harbor-harbor-core           ClusterIP  10.100.245.179  <none>       80/TCP             2m7s
harbor-harbor-database       ClusterIP  10.100.28.121   <none>       5432/TCP           2m7s
harbor-harbor-jobservice     ClusterIP  10.100.49.48    <none>       80/TCP             2m7s
harbor-harbor-notary-server  ClusterIP  10.100.46.37    <none>       4443/TCP           2m7s
harbor-harbor-notary-signer  ClusterIP  10.100.213.224  <none>       7899/TCP           2m7s
harbor-harbor-portal         ClusterIP  10.100.152.224  <none>       80/TCP             2m7s
harbor-harbor-redis          ClusterIP  10.100.69.123   <none>       6379/TCP           2m7s
harbor-harbor-registry       ClusterIP  10.100.211.253  <none>       5000/TCP,8080/TCP  2m7s

==> v1/StatefulSet
NAME                    READY  AGE
harbor-harbor-database  1/1    2m7s
harbor-harbor-redis     1/1    2m7s

==> v1beta1/Ingress
NAME                   HOSTS                              ADDRESS        PORTS    AGE
harbor-harbor-ingress  core.mylabs.dev,notary.mylabs.dev  18.194.224.42  80, 443  2m7s


NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://core.mylabs.dev.
For more details, please visit https://github.com/goharbor/harbor.
```

Check how the Ingress looks like:

```bash
kubectl describe ingresses -n harbor-system harbor-harbor-ingress
```

Output:

```text
Name:             harbor-harbor-ingress
Namespace:        harbor-system
Address:          18.194.224.42
Default backend:  default-http-backend:80 (<none>)
TLS:
  ingress-cert-staging terminates core.mylabs.dev
  ingress-cert-staging terminates notary.mylabs.dev
Rules:
  Host               Path  Backends
  ----               ----  --------
  core.mylabs.dev
                     /             harbor-harbor-portal:80 (<none>)
                     /api/         harbor-harbor-core:80 (<none>)
                     /service/     harbor-harbor-core:80 (<none>)
                     /v2/          harbor-harbor-core:80 (<none>)
                     /chartrepo/   harbor-harbor-core:80 (<none>)
                     /c/           harbor-harbor-core:80 (<none>)
  notary.mylabs.dev
                     /   harbor-harbor-notary-server:4443 (<none>)
Annotations:
  ingress.kubernetes.io/ssl-redirect:           true
  nginx.ingress.kubernetes.io/proxy-body-size:  0
  nginx.ingress.kubernetes.io/ssl-redirect:     true
  ingress.kubernetes.io/proxy-body-size:        0
Events:
  Type    Reason  Age    From                      Message
  ----    ------  ----   ----                      -------
  Normal  CREATE  3m11s  nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
  Normal  UPDATE  3m1s   nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
```

Open the [https://core.mylabs.dev](https://core.mylabs.dev) and log in as `admin`/`admin`.

You should see the Web UI:

![Harbor](./harbor_projects.png "Harbor")
