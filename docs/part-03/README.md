# Nginx + cert-manager installation

Before we move on with other tasks it is necessary to install Nginx Ingress.
It's also handy to install cert-manager for managing TLS certificates.

## Install cert-manager

Install the CRDs resources separately:

```bash
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml
```

Create the namespace for cert-manager and label it to disable resource
validation:

```bash
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

Install the cert-manager Helm chart:

```bash
helm repo add jetstack https://charts.jetstack.io
helm install --name cert-manager --namespace cert-manager --wait jetstack/cert-manager --version v0.7.2
```

Output:

```text
NAME:   cert-manager
LAST DEPLOYED: Mon May  6 11:28:20 2019
NAMESPACE: cert-manager
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                                    AGE
cert-manager-edit                       24s
cert-manager-view                       24s
cert-manager-webhook:webhook-requester  24s

==> v1/Pod(related)
NAME                                     READY  STATUS   RESTARTS  AGE
cert-manager-86c45c86c8-c774g            1/1    Running  0         24s
cert-manager-cainjector-6885996d5-nsb8z  1/1    Running  0         24s
cert-manager-webhook-59dfddccfd-wc6j4    1/1    Running  0         24s

==> v1/Service
NAME                  TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
cert-manager-webhook  ClusterIP  10.100.194.147  <none>       443/TCP  24s

==> v1/ServiceAccount
NAME                     SECRETS  AGE
cert-manager             1        24s
cert-manager-cainjector  1        24s
cert-manager-webhook     1        24s

==> v1alpha1/Certificate
NAME                              AGE
cert-manager-webhook-ca           24s
cert-manager-webhook-webhook-tls  24s

==> v1alpha1/Issuer
NAME                           AGE
cert-manager-webhook-ca        24s
cert-manager-webhook-selfsign  24s

==> v1beta1/APIService
NAME                                  AGE
v1beta1.admission.certmanager.k8s.io  24s

==> v1beta1/ClusterRole
NAME                     AGE
cert-manager             24s
cert-manager-cainjector  24s

==> v1beta1/ClusterRoleBinding
NAME                                 AGE
cert-manager                         24s
cert-manager-cainjector              24s
cert-manager-webhook:auth-delegator  24s

==> v1beta1/Deployment
NAME                     READY  UP-TO-DATE  AVAILABLE  AGE
cert-manager             1/1    1           1          24s
cert-manager-cainjector  1/1    1           1          24s
cert-manager-webhook     1/1    1           1          24s

==> v1beta1/RoleBinding
NAME                                                AGE
cert-manager-webhook:webhook-authentication-reader  24s

==> v1beta1/ValidatingWebhookConfiguration
NAME                  AGE
cert-manager-webhook  24s


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

```bash
export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY_BASE64=$(echo -n "$EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY" | base64)
envsubst < files/cert-manager-letsencrypt-aws-route53-clusterissuer.yaml | kubectl apply -f -
cat files/cert-manager-letsencrypt-aws-route53-clusterissuer.yaml
```

Output:

```text
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

## Install Nginx

Install Nginx which will also create a new loadbalancer:

```bash
helm install stable/nginx-ingress --wait --name nginx-ingress --namespace nginx-ingress-system --set rbac.create=true
```

Output:

```text
NAME:   nginx-ingress
LAST DEPLOYED: Mon May  6 11:29:31 2019
NAMESPACE: nginx-ingress-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                      DATA  AGE
nginx-ingress-controller  1     2s

==> v1/Pod(related)
NAME                                           READY  STATUS             RESTARTS  AGE
nginx-ingress-controller-ffc964cd-6npjn        0/1    ContainerCreating  0         2s
nginx-ingress-default-backend-56768c457-nj6jd  0/1    ContainerCreating  0         2s

==> v1/Service
NAME                           TYPE          CLUSTER-IP      EXTERNAL-IP       PORT(S)                     AGE
nginx-ingress-controller       LoadBalancer  10.100.82.132   a73fdbe796fe1...  80:32424/TCP,443:30456/TCP  2s
nginx-ingress-default-backend  ClusterIP     10.100.252.170  <none>            80/TCP                      2s

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
```

![Architecture](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/crystal.svg?sanitize=true
"Architecture")
