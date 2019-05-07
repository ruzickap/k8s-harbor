# Install Harbor

Generate certificate using cert-manager:

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

![ACME DNS Challenge](https://b3n.org/wp-content/uploads/2016/09/acme_letsencrypt_dns-01-challenge.png
"ACME DNS Challenge")

([https://b3n.org/intranet-ssl-certificates-using-lets-encrypt-dns-01/](https://b3n.org/intranet-ssl-certificates-using-lets-encrypt-dns-01/))

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
  Creation Timestamp:  2019-05-06T09:30:35Z
  Generation:          1
  Resource Version:    5435
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/harbor-system/certificates/ingress-cert-staging
  UID:                 9a1cda81-6fe1-11e9-a6e8-06a736553d32
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
    Last Transition Time:  2019-05-06T09:34:28Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2019-08-04T08:34:27Z
Events:
  Type    Reason              Age    From          Message
  ----    ------              ----   ----          -------
  Normal  Generated           9m9s   cert-manager  Generated new private key
  Normal  GenerateSelfSigned  9m9s   cert-manager  Generated temporary self signed certificate
  Normal  OrderCreated        9m9s   cert-manager  Created Order resource "ingress-cert-staging-3500457514"
  Normal  OrderComplete       5m16s  cert-manager  Order "ingress-cert-staging-3500457514" completed successfully
  Normal  CertIssued          5m16s  cert-manager  Certificate issued successfully
```

The Kubernetes "secret" should contain the certificates:

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
              certmanager.k8s.io/ip-sans:
              certmanager.k8s.io/issuer-kind: ClusterIssuer
              certmanager.k8s.io/issuer-name: letsencrypt-staging-dns

Type:  kubernetes.io/tls

Data
====
ca.crt:   0 bytes
tls.crt:  3553 bytes
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
cd ..
```

Output:

```text
NAME:   harbor
LAST DEPLOYED: Mon May  6 11:41:06 2019
NAMESPACE: harbor-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                         DATA  AGE
harbor-harbor-adminserver    39    2m25s
harbor-harbor-chartmuseum    24    2m25s
harbor-harbor-clair          1     2m25s
harbor-harbor-core           1     2m25s
harbor-harbor-jobservice     1     2m25s
harbor-harbor-notary-server  5     2m25s
harbor-harbor-registry       2     2m25s

==> v1/Deployment
NAME                         READY  UP-TO-DATE  AVAILABLE  AGE
harbor-harbor-adminserver    1/1    1           1          2m25s
harbor-harbor-chartmuseum    1/1    1           1          2m25s
harbor-harbor-clair          1/1    1           1          2m25s
harbor-harbor-core           1/1    1           1          2m25s
harbor-harbor-jobservice     1/1    1           1          2m25s
harbor-harbor-notary-server  1/1    1           1          2m25s
harbor-harbor-notary-signer  1/1    1           1          2m25s
harbor-harbor-portal         1/1    1           1          2m25s
harbor-harbor-registry       1/1    1           1          2m25s

==> v1/Pod(related)
NAME                                         READY  STATUS   RESTARTS  AGE
harbor-harbor-adminserver-5bd466b57f-vftrk   1/1    Running  1         2m25s
harbor-harbor-chartmuseum-dbcb6c5db-9gxm8    1/1    Running  0         2m25s
harbor-harbor-clair-6cb966575d-pmdmq         1/1    Running  1         2m25s
harbor-harbor-core-bdc64bc65-hclfw           1/1    Running  0         2m25s
harbor-harbor-database-0                     1/1    Running  0         2m24s
harbor-harbor-jobservice-6d74d76bdf-84bpt    1/1    Running  0         2m25s
harbor-harbor-notary-server-857d5c7c5-tspqn  1/1    Running  1         2m25s
harbor-harbor-notary-signer-7cbd9967f-m4qqh  1/1    Running  0         2m25s
harbor-harbor-portal-5c57c5dfcb-2lz2t        1/1    Running  0         2m24s
harbor-harbor-redis-0                        1/1    Running  0         2m24s
harbor-harbor-registry-74c5bf8598-hpvx9      2/2    Running  0         2m24s

==> v1/Secret
NAME                       TYPE    DATA  AGE
harbor-harbor-adminserver  Opaque  4     2m25s
harbor-harbor-chartmuseum  Opaque  1     2m25s
harbor-harbor-core         Opaque  4     2m25s
harbor-harbor-database     Opaque  1     2m25s
harbor-harbor-jobservice   Opaque  1     2m25s
harbor-harbor-registry     Opaque  1     2m25s

==> v1/Service
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
harbor-harbor-adminserver    ClusterIP  10.100.157.29   <none>       80/TCP             2m25s
harbor-harbor-chartmuseum    ClusterIP  10.100.209.244  <none>       80/TCP             2m25s
harbor-harbor-clair          ClusterIP  10.100.7.4      <none>       6060/TCP           2m25s
harbor-harbor-core           ClusterIP  10.100.111.152  <none>       80/TCP             2m25s
harbor-harbor-database       ClusterIP  10.100.15.103   <none>       5432/TCP           2m25s
harbor-harbor-jobservice     ClusterIP  10.100.191.184  <none>       80/TCP             2m25s
harbor-harbor-notary-server  ClusterIP  10.100.186.231  <none>       4443/TCP           2m25s
harbor-harbor-notary-signer  ClusterIP  10.100.6.37     <none>       7899/TCP           2m25s
harbor-harbor-portal         ClusterIP  10.100.228.126  <none>       80/TCP             2m25s
harbor-harbor-redis          ClusterIP  10.100.70.201   <none>       6379/TCP           2m25s
harbor-harbor-registry       ClusterIP  10.100.86.196   <none>       5000/TCP,8080/TCP  2m25s

==> v1/StatefulSet
NAME                    READY  AGE
harbor-harbor-database  1/1    2m25s
harbor-harbor-redis     1/1    2m24s

==> v1beta1/Ingress
NAME                   HOSTS                              ADDRESS         PORTS    AGE
harbor-harbor-ingress  core.mylabs.dev,notary.mylabs.dev  18.195.168.215  80, 443  2m24s


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
Address:          18.195.168.215
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
  ingress.kubernetes.io/proxy-body-size:        0
  ingress.kubernetes.io/ssl-redirect:           true
  nginx.ingress.kubernetes.io/proxy-body-size:  0
  nginx.ingress.kubernetes.io/ssl-redirect:     true
Events:
  Type    Reason  Age   From                      Message
  ----    ------  ----  ----                      -------
  Normal  CREATE  14m   nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
  Normal  UPDATE  13m   nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
  ```

Check the SSL certificate:

```bash
echo | openssl s_client -showcerts -connect core.${MY_DOMAIN}:443 2>/dev/null | openssl x509 -inform pem -noout -text
```

Output:

```text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            03:ba:eb:a2:34:43:0c:ae:7b:63:64:4d:4a:ee:c1:25:b4:35
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
        Validity
            Not Before: Mar 29 08:46:52 2019 GMT
            Not After : Jun 27 08:46:52 2019 GMT
        Subject: CN = *.mylabs.dev
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                AB:60:E9:ED:3F:40:72:83:7D:62:08:F9:EB:8F:EA:1C:42:CC:76:4E
            X509v3 Authority Key Identifier:
                keyid:A8:4A:6A:63:04:7D:DD:BA:E6:D1:39:B7:A6:45:65:EF:F3:A8:EC:A1

            Authority Information Access:
                OCSP - URI:http://ocsp.int-x3.letsencrypt.org
                CA Issuers - URI:http://cert.int-x3.letsencrypt.org/

            X509v3 Subject Alternative Name:
                DNS:*.mylabs.dev, DNS:mylabs.dev
            X509v3 Certificate Policies:
                Policy: 2.23.140.1.2.1
                Policy: 1.3.6.1.4.1.44947.1.1.1
                  CPS: http://cps.letsencrypt.org
...
```

Open the [https://core.mylabs.dev](https://core.mylabs.dev):

![Harbor login page](./harbor_login_page.png "Harbor login page")

Log in:

* User: admin
* Password: admin

You should see the Web UI:

![Harbor](./harbor_projects.png "Harbor")
