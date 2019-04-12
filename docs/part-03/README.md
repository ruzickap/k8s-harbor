# Nginx + cert-manager installation

Before we move on with other tasks it is necessary to install Nginx Ingress.
It's also handy to install cert-manager for managing TLS certificates.

## Install cert-manager

Install the CRDs resources separately:

```bash
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
```

Create the namespace for cert-manager and label it to disable resource
validation:

```bash
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

Install the cert-manager Helm chart:

```bash
helm install --name cert-manager --namespace cert-manager --version v0.6.6 --wait stable/cert-manager
```

Output:

```text
NAME:   cert-manager
LAST DEPLOYED: Fri Apr 12 08:58:39 2019
NAMESPACE: cert-manager
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME                                    AGE
cert-manager-edit                       2m23s
cert-manager-view                       2m23s
cert-manager-webhook:webhook-requester  2m23s

==> v1/ConfigMap
NAME                          DATA  AGE
cert-manager-webhook-ca-sync  1     2m23s

==> v1/Job
NAME                          COMPLETIONS  DURATION  AGE
cert-manager-webhook-ca-sync  1/1          99s       2m23s

==> v1/Pod(related)
NAME                                   READY  STATUS     RESTARTS  AGE
cert-manager-6d47b6c444-6h7dw          1/1    Running    0         2m23s
cert-manager-webhook-84cfc4d76f-cjjwz  1/1    Running    0         2m23s
cert-manager-webhook-ca-sync-mp9d7     0/1    Completed  4         2m23s

==> v1/Service
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)  AGE
cert-manager-webhook  ClusterIP  10.100.17.138  <none>       443/TCP  2m23s

==> v1/ServiceAccount
NAME                          SECRETS  AGE
cert-manager                  1        2m23s
cert-manager-webhook          1        2m23s
cert-manager-webhook-ca-sync  1        2m23s

==> v1alpha1/Certificate
NAME                              AGE
cert-manager-webhook-ca           2m23s
cert-manager-webhook-webhook-tls  2m23s

==> v1alpha1/Issuer
NAME                           AGE
cert-manager-webhook-ca        2m23s
cert-manager-webhook-selfsign  2m23s

==> v1beta1/APIService
NAME                                  AGE
v1beta1.admission.certmanager.k8s.io  2m23s

==> v1beta1/ClusterRole
NAME                          AGE
cert-manager                  2m23s
cert-manager-webhook-ca-sync  2m23s

==> v1beta1/ClusterRoleBinding
NAME                                 AGE
cert-manager                         2m23s
cert-manager-webhook-ca-sync         2m23s
cert-manager-webhook:auth-delegator  2m23s

==> v1beta1/CronJob
NAME                          SCHEDULE  SUSPEND  ACTIVE  LAST SCHEDULE  AGE
cert-manager-webhook-ca-sync  @weekly   False    0       <none>         2m23s

==> v1beta1/Deployment
NAME                  READY  UP-TO-DATE  AVAILABLE  AGE
cert-manager          1/1    1           1          2m23s
cert-manager-webhook  1/1    1           1          2m23s

==> v1beta1/RoleBinding
NAME                                                AGE
cert-manager-webhook:webhook-authentication-reader  2m23s

==> v1beta1/ValidatingWebhookConfiguration
NAME                  AGE
cert-manager-webhook  2m23s


NOTES:
cert-manager has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.readthedocs.io/en/latest/reference/issuers.html

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.readthedocs.io/en/latest/reference/ingress-shim.html
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

## Install Nginx

Install Nginx which will also create a new loadbalancer:

```bash
helm install stable/nginx-ingress --name nginx-ingress --namespace nginx-ingress-system --set rbac.create=true
```

Output:

```text
NAME:   nginx-ingress
LAST DEPLOYED: Fri Apr 12 09:04:21 2019
NAMESPACE: nginx-ingress-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                      DATA  AGE
nginx-ingress-controller  1     1s

==> v1/Pod(related)
NAME                                            READY  STATUS             RESTARTS  AGE
nginx-ingress-controller-7476b9c767-k8gd7       0/1    ContainerCreating  0         0s
nginx-ingress-default-backend-544cfb69fc-6627d  0/1    ContainerCreating  0         0s

==> v1/Service
NAME                           TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)                     AGE
nginx-ingress-controller       LoadBalancer  10.100.227.94   <pending>    80:31951/TCP,443:32106/TCP  0s
nginx-ingress-default-backend  ClusterIP     10.100.117.118  <none>       80/TCP                      0s

==> v1/ServiceAccount
NAME           SECRETS  AGE
nginx-ingress  1        1s

==> v1beta1/ClusterRole
NAME           AGE
nginx-ingress  1s

==> v1beta1/ClusterRoleBinding
NAME           AGE
nginx-ingress  1s

==> v1beta1/Deployment
NAME                           READY  UP-TO-DATE  AVAILABLE  AGE
nginx-ingress-controller       0/1    1           0          0s
nginx-ingress-default-backend  0/1    1           0          0s

==> v1beta1/Role
NAME           AGE
nginx-ingress  1s

==> v1beta1/RoleBinding
NAME           AGE
nginx-ingress  1s
...
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
