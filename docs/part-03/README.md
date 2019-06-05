# Nginx + cert-manager installation

Before we move on with other tasks it is necessary to install Nginx Ingress.
It's also handy to install cert-manager for managing TLS certificates.

## Install cert-manager

cert-manager architecture:

![cert-manager high level overview](https://raw.githubusercontent.com/jetstack/cert-manager/4f30ed75e88e5d0defeb950501b5cac6da7fa7fe/docs/images/high-level-overview.png
"cert-manager high level overview")

Install the CRDs resources separately:

```bash
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
```

Output:

```text
customresourcedefinition.apiextensions.k8s.io/certificates.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/challenges.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/issuers.certmanager.k8s.io created
customresourcedefinition.apiextensions.k8s.io/orders.certmanager.k8s.io created
```

Create the namespace for cert-manager and label it to disable resource
validation:

```bash
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

Output:

```text
namespace/cert-manager created
namespace/cert-manager labeled
```

Install the cert-manager Helm chart:

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install --name cert-manager --namespace cert-manager --wait jetstack/cert-manager --version v0.8.0 --set webhook.enabled=false
```

Output:

```text
"jetstack" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
NAME:   cert-manager
LAST DEPLOYED: Wed Jun  5 14:29:52 2019
NAMESPACE: cert-manager
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME               AGE
cert-manager-edit  12s
cert-manager-view  12s

==> v1/Pod(related)
NAME                                      READY  STATUS   RESTARTS  AGE
cert-manager-7548788b6-94zdp              1/1    Running  0         12s
cert-manager-cainjector-5675c6fcc7-plbkr  1/1    Running  0         12s

==> v1/ServiceAccount
NAME                     SECRETS  AGE
cert-manager             1        12s
cert-manager-cainjector  1        12s

==> v1beta1/ClusterRole
NAME                     AGE
cert-manager             12s
cert-manager-cainjector  12s

==> v1beta1/ClusterRoleBinding
NAME                     AGE
cert-manager             12s
cert-manager-cainjector  12s

==> v1beta1/Deployment
NAME                     READY  UP-TO-DATE  AVAILABLE  AGE
cert-manager             1/1    1           1          12s
cert-manager-cainjector  1/1    1           1          12s


NOTES:
cert-manager has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://docs.cert-manager.io/en/latest/reference/issuers.html

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://docs.cert-manager.io/en/latest/reference/ingress-shim.html
```

### Create ClusterIssuer for Let's Encrypt

Create `ClusterIssuer` for Route53 used by cert-manager. It will allow Let's
Encrypt to generate certificate. Route53 (DNS) method of requesting certificate
from Let's Encrypt must be used to create wildcard certificate `*.mylabs.dev`
(details [here](https://community.letsencrypt.org/t/wildcard-certificates-via-http-01/51223)).

![ACME DNS Challenge](https://b3n.org/wp-content/uploads/2016/09/acme_letsencrypt_dns-01-challenge.png
"ACME DNS Challenge")

```bash
export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY_BASE64=$(echo -n "$EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY" | base64)
envsubst < files/cert-manager-letsencrypt-aws-route53-clusterissuer.yaml | kubectl apply -f -
cat files/cert-manager-letsencrypt-aws-route53-clusterissuer.yaml
```

Output:

```text
secret/aws-route53-secret-access-key-secret created
clusterissuer.certmanager.k8s.io/letsencrypt-staging-dns created
clusterissuer.certmanager.k8s.io/letsencrypt-production-dns created
apiVersion: v1
kind: Secret
metadata:
  name: aws-route53-secret-access-key-secret
  namespace: cert-manager
data:
  secret-access-key: $EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY_BASE64
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging-dns
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: petr.ruzicka@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-staging-dns
    dns01:
      # Here we define a list of DNS-01 providers that can solve DNS challenges
      providers:
      - name: aws-route53
        route53:
          accessKeyID: ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID}
          region: eu-central-1
          secretAccessKeySecretRef:
            name: aws-route53-secret-access-key-secret
            key: secret-access-key
---
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production-dns
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: petr.ruzicka@gmail.com
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-production-dns
    dns01:
      # Here we define a list of DNS-01 providers that can solve DNS challenges
      # https://docs.cert-manager.io/en/latest/tasks/acme/configuring-dns01/index.html
      providers:
      - name: aws-route53
        route53:
          accessKeyID: ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID}
          region: eu-central-1
          secretAccessKeySecretRef:
            name: aws-route53-secret-access-key-secret
            key: secret-access-key
```

![ACME DNS Challenge](https://b3n.org/wp-content/uploads/2016/09/acme_letsencrypt_dns-01-challenge.png
"ACME DNS Challenge")

([https://b3n.org/intranet-ssl-certificates-using-lets-encrypt-dns-01/](https://b3n.org/intranet-ssl-certificates-using-lets-encrypt-dns-01/))

## Generate TLS certificate

Create certificate using cert-manager

```bash
envsubst < files/cert-manager-letsencrypt-aws-route53-certificate.yaml | kubectl apply -f -
cat files/cert-manager-letsencrypt-aws-route53-certificate.yaml
```

Output:

```text
certificate.certmanager.k8s.io/ingress-cert-production created
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  namespace: cert-manager
spec:
  secretName: ingress-cert-${LETSENCRYPT_ENVIRONMENT}
  issuerRef:
    kind: ClusterIssuer
    name: letsencrypt-${LETSENCRYPT_ENVIRONMENT}-dns
  commonName: "*.${MY_DOMAIN}"
  dnsNames:
  - "*.${MY_DOMAIN}"
  acme:
    config:
    - dns01:
        provider: aws-route53
      domains:
      - "*.${MY_DOMAIN}"
```

![cert-manager - Create certificate](https://i1.wp.com/blog.openshift.com/wp-content/uploads/OCP-PKI-and-certificates-cert-manager.png
"cert-manager - Create certificate")

([https://blog.openshift.com/self-serviced-end-to-end-encryption-approaches-for-applications-deployed-in-openshift/](https://blog.openshift.com/self-serviced-end-to-end-encryption-approaches-for-applications-deployed-in-openshift/))

## Install kubed

It's necessary to copy the wildcard certificate across all "future" namespaces
and that's the reason why [kubed](https://github.com/appscode/kubed) needs to be
installed (for now).

Add kubed helm repository:

```bash
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
```

Output:

```text
"appscode" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "appscode" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```

Install kubed:

```bash
helm install appscode/kubed --name kubed --version 0.10.0 --namespace kube-system --wait \
  --set config.clusterName=my_k8s_cluster \
  --set apiserver.enabled=false
```

Output:

```text
NAME:   kubed
LAST DEPLOYED: Wed Jun  5 14:30:28 2019
NAMESPACE: kube-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME         AGE
kubed-kubed  2s

==> v1/ClusterRoleBinding
NAME                                  AGE
kubed-kubed                           2s
kubed-kubed-apiserver-auth-delegator  2s

==> v1/Pod(related)
NAME                         READY  STATUS             RESTARTS  AGE
kubed-kubed-76b4dcd9f-qbbqw  0/1    ContainerCreating  0         2s

==> v1/RoleBinding
NAME                                                          AGE
kubed-kubed-apiserver-extension-server-authentication-reader  2s

==> v1/Secret
NAME                        TYPE    DATA  AGE
kubed-kubed                 Opaque  1     2s
kubed-kubed-apiserver-cert  Opaque  2     3s

==> v1/Service
NAME         TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)  AGE
kubed-kubed  ClusterIP  10.100.112.12  <none>       443/TCP  2s

==> v1/ServiceAccount
NAME         SECRETS  AGE
kubed-kubed  1        2s

==> v1beta1/Deployment
NAME         READY  UP-TO-DATE  AVAILABLE  AGE
kubed-kubed  0/1    1           0          2s


NOTES:
To verify that Kubed has started, run:

  kubectl --namespace=kube-system get deployments -l "release=kubed, app=kubed"
```

Annotate (mark) the cert-manager secret to be copied to other namespaces
if necessary:

```bash
kubectl annotate secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n cert-manager kubed.appscode.com/sync="app=kubed"
```

Output:

```text
secret/ingress-cert-production annotated
```

## Install Nginx

![Nginx Ingress controller](https://www.nginx.com/wp-content/uploads/2018/12/multiple-ingress-controllers.png
"Nginx Ingress controller")

([https://www.nginx.com/blog/](https://www.nginx.com/blog/))

Install nginx-ingress which will also create a new loadbalancer:

```bash
helm install stable/nginx-ingress --wait --name nginx-ingress --namespace nginx-ingress-system --version 1.6.11 \
  --set rbac.create=true \
  --set controller.extraArgs.default-ssl-certificate=cert-manager/ingress-cert-${LETSENCRYPT_ENVIRONMENT}
```

Output:

```text
NAME:   nginx-ingress
LAST DEPLOYED: Wed Jun  5 14:30:40 2019
NAMESPACE: nginx-ingress-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                      DATA  AGE
nginx-ingress-controller  1     2s

==> v1/Pod(related)
NAME                                            READY  STATUS             RESTARTS  AGE
nginx-ingress-controller-947555496-9nf54        0/1    ContainerCreating  0         2s
nginx-ingress-default-backend-6694789b87-bkmj7  0/1    ContainerCreating  0         2s

==> v1/Service
NAME                           TYPE          CLUSTER-IP     EXTERNAL-IP       PORT(S)                     AGE
nginx-ingress-controller       LoadBalancer  10.100.244.69  aba9e9103878d...  80:31279/TCP,443:31552/TCP  2s
nginx-ingress-default-backend  ClusterIP     10.100.71.100  <none>            80/TCP                      2s

==> v1/ServiceAccount
NAME           SECRETS  AGE
nginx-ingress  1        2s

==> v1beta1/ClusterRole
NAME           AGE
nginx-ingress  2s

==> v1beta1/ClusterRoleBinding
NAME           AGE
nginx-ingress  2s

==> v1beta1/Deployment
NAME                           READY  UP-TO-DATE  AVAILABLE  AGE
nginx-ingress-controller       0/1    1           0          2s
nginx-ingress-default-backend  0/1    1           0          2s

==> v1beta1/Role
NAME           AGE
nginx-ingress  2s

==> v1beta1/RoleBinding
NAME           AGE
nginx-ingress  2s


NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace nginx-ingress-system get services -o wide -w nginx-ingress-controller'

An example Ingress that makes use of the controller:

  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

## Create DNS records

Create DNS record `mylabs.dev` for the loadbalancer created by Nginx ingress:

```bash
export LOADBALANCER_HOSTNAME=$(kubectl get svc nginx-ingress-controller -n nginx-ingress-system -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
export CANONICAL_HOSTED_ZONE_NAME_ID=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?DNSName==\`$LOADBALANCER_HOSTNAME\`].CanonicalHostedZoneNameID" --output text)
export HOSTED_ZONE_ID=$(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text)

envsubst < files/aws_route53-dns_change.json | aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch=file:///dev/stdin
sleep 100
```

Output:

```text
{
    "ChangeInfo": {
        "Id": "/change/CWW2GSS39JTSW",
        "Status": "PENDING",
        "SubmittedAt": "2019-06-05T12:30:55.095Z",
        "Comment": "A new record set for the zone."
    }
}
```

![Architecture](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/crystal.svg?sanitize=true
"Architecture")

You should see the following output form cert-manager when looking at
certificates:

```bash
kubectl describe certificates -n cert-manager ingress-cert-${LETSENCRYPT_ENVIRONMENT}
```

Output

```text
Name:         ingress-cert-production
Namespace:    cert-manager
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"ingress-cert-production","namespace"...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2019-06-05T12:30:21Z
  Generation:          1
  Resource Version:    6493
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/cert-manager/certificates/ingress-cert-production
  UID:                 afb37042-878d-11e9-9a91-0668fe0cab46
Spec:
  Acme:
    Config:
      Dns 01:
        Provider:  aws-route53
      Domains:
        *.mylabs.dev
  Common Name:  *.mylabs.dev
  Dns Names:
    *.mylabs.dev
  Issuer Ref:
    Kind:       ClusterIssuer
    Name:       letsencrypt-production-dns
  Secret Name:  ingress-cert-production
Status:
  Conditions:
    Last Transition Time:  2019-06-05T12:32:08Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2019-09-03T11:32:06Z
Events:
  Type    Reason              Age    From          Message
  ----    ------              ----   ----          -------
  Normal  Generated           2m15s  cert-manager  Generated new private key
  Normal  GenerateSelfSigned  2m15s  cert-manager  Generated temporary self signed certificate
  Normal  OrderCreated        2m15s  cert-manager  Created Order resource "ingress-cert-production-20059064"
  Normal  OrderComplete       29s    cert-manager  Order "ingress-cert-production-20059064" completed successfully
  Normal  CertIssued          29s    cert-manager  Certificate issued successfully
```

The Kubernetes "secret" in `cert-manager` namespace should contain the
certificates:

```bash
kubectl describe secret -n cert-manager ingress-cert-${LETSENCRYPT_ENVIRONMENT}
```

Output:

```text
Name:         ingress-cert-production
Namespace:    cert-manager
Labels:       certmanager.k8s.io/certificate-name=ingress-cert-production
Annotations:  certmanager.k8s.io/alt-names: *.mylabs.dev
              certmanager.k8s.io/common-name: *.mylabs.dev
              certmanager.k8s.io/ip-sans:
              certmanager.k8s.io/issuer-kind: ClusterIssuer
              certmanager.k8s.io/issuer-name: letsencrypt-production-dns
              kubed.appscode.com/sync: app=kubed

Type:  kubernetes.io/tls

Data
====
tls.key:  1679 bytes
ca.crt:   0 bytes
tls.crt:  3550 bytes
```

Check the SSL certificate:

```bash
echo | openssl s_client -showcerts -connect ${MY_DOMAIN}:443 2>/dev/null | openssl x509 -inform pem -noout -text
```

Output:

```text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            03:2a:03:1d:e0:c4:2e:f5:0f:2d:89:a6:b5:0e:a9:f8:32:9f
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
        Validity
            Not Before: Jun  5 11:32:06 2019 GMT
            Not After : Sep  3 11:32:06 2019 GMT
        Subject: CN = *.mylabs.dev
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
...
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                0B:35:19:82:BD:96:C3:88:B2:F8:07:70:BE:4A:83:47:A8:08:B9:C4
            X509v3 Authority Key Identifier:
                keyid:A8:4A:6A:63:04:7D:DD:BA:E6:D1:39:B7:A6:45:65:EF:F3:A8:EC:A1

            Authority Information Access:
                OCSP - URI:http://ocsp.int-x3.letsencrypt.org
                CA Issuers - URI:http://cert.int-x3.letsencrypt.org/

            X509v3 Subject Alternative Name:
                DNS:*.mylabs.dev
            X509v3 Certificate Policies:
                Policy: 2.23.140.1.2.1
                Policy: 1.3.6.1.4.1.44947.1.1.1
                  CPS: http://cps.letsencrypt.org
...
```

## Install [Argo CD](https://github.com/argoproj/argo-cd)

Create namespace for Argo CD:

```bash
kubectl create namespace argocd-system
kubectl label namespace argocd-system app=kubed
```

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
envsubst < files/argo-cd_helm_chart_values.yaml | helm install --name argocd --namespace argocd-system --wait argo/argo-cd --version 0.2.2 --values -
```

Output:

```text
"argo" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "appscode" chart repository
...Successfully got an update from the "argo" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
NAME:   argocd
LAST DEPLOYED: Wed Jun  5 14:32:50 2019
NAMESPACE: argocd-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                           AGE
argocd-application-controller  53s
argocd-server                  53s

==> v1/ClusterRoleBinding
NAME                           AGE
argocd-application-controller  53s
argocd-server                  53s

==> v1/ConfigMap
NAME            DATA  AGE
argocd-cm       3     53s
argocd-rbac-cm  0     53s

==> v1/Deployment
NAME                           READY  UP-TO-DATE  AVAILABLE  AGE
argocd-application-controller  1/1    1           1          53s
argocd-dex-server              1/1    1           1          53s
argocd-redis                   1/1    1           1          53s
argocd-repo-server             1/1    1           1          53s
argocd-server                  1/1    1           1          53s

==> v1/Pod(related)
NAME                                            READY  STATUS   RESTARTS  AGE
argocd-application-controller-5fbf79c7b9-bxpd9  1/1    Running  0         53s
argocd-dex-server-64869cbfcf-45mjg              1/1    Running  0         53s
argocd-redis-78d8767bc8-4rqbs                   1/1    Running  0         53s
argocd-repo-server-5fd94b46c-6kg9w              1/1    Running  0         53s
argocd-server-7f95ffdf86-ct7nq                  1/1    Running  0         53s

==> v1/Role
NAME                           AGE
argocd-application-controller  53s
argocd-dex-server              53s
argocd-server                  53s

==> v1/RoleBinding
NAME                           AGE
argocd-application-controller  53s
argocd-dex-server              53s
argocd-server                  53s

==> v1/Secret
NAME           TYPE    DATA  AGE
argocd-secret  Opaque  5     53s

==> v1/Service
NAME                           TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
argocd-application-controller  ClusterIP  10.100.183.200  <none>       8082/TCP           53s
argocd-dex-server              ClusterIP  10.100.143.184  <none>       5556/TCP,5557/TCP  53s
argocd-metrics                 ClusterIP  10.100.5.209    <none>       8082/TCP           53s
argocd-redis                   ClusterIP  10.100.105.250  <none>       6379/TCP           53s
argocd-repo-server             ClusterIP  10.100.67.17    <none>       8081/TCP           53s
argocd-server                  ClusterIP  10.100.56.192   <none>       80/TCP,443/TCP     53s

==> v1/ServiceAccount
NAME                           SECRETS  AGE
argocd-application-controller  1        53s
argocd-dex-server              1        53s
argocd-server                  1        53s


NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward svc/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress and check the first option ssl passthrough:
    https://github.com/argoproj/argo-cd/blob/master/docs/ingress.md#option-1-ssl-passthrough

After reaching the UI the first time you can login with username: admin and the password will be the
name of the server pod. You can get the pod name by running:

kubectl get pods -n argocd -l app.kubernetes.io/name=argo-cd-server -o name | cut -d'/' -f 2
```

Argo CD architecture:

![Argo CD - Architecture](https://raw.githubusercontent.com/argoproj/argo-cd/f5bc901dd722290bcba63229cee6e112b9e55935/docs/assets/argocd_architecture.png
"Argo CD - Architecture")

Change Argo CD for username `admin` to have password `admin`:

```bash
kubectl patch secret argocd-secret -n argocd-system --type="json" -p="[{\"op\" : \"replace\" ,\"path\" : \"/data/admin.password\" ,\"value\" : \"JDJ5JDEwJDhtWVdWZTBrVWZibkExLnc2LmloQnVOMVZTdi5Sc0ZGYWlOOGV5U2dxQXdYM1NpOGJSM0l1\"}]"
```

Try to access the Argo CD using the URL [https://argocd.mylabs.dev](https://argocd.mylabs.dev)
with following credentials:

* Username: `admin`
* Password: `admin`

Configure Ingress for Argo CD:

```bash
envsubst < files/argo-cd_ingress.yaml | kubectl apply -f -
```

Output:

```text
ingress.extensions/argocd-server-http-ingress created
ingress.extensions/argocd-server-grpc-ingress created
```

There are now two domains:

* HTTPS: [https://argocd.mylabs.dev](https://argocd.mylabs.dev)
* GRPC: argocd-grpc.mylabs.dev

Download [Argo CD client](https://github.com/argoproj/argo-cd/releases):

```bash
if [ ! -x /usr/local/bin/argocd ]; then
  sudo curl -s -Lo /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v1.0.0/argocd-linux-amd64
  sudo chmod a+x /usr/local/bin/argocd
fi
```
