# Install Harbor

Harbor architecture:

![Harbor Architecture](https://raw.githubusercontent.com/goharbor/harbor/5d31dd5b57d83f300907744aabf13ca60aac19b3/docs/img/harbor-arch.png
"Harbor Architecture")

Generate certificate using cert-manager:

```bash
kubectl create namespace harbor-system
envsubst < files/cert-manager-letsencrypt-aws-route53-certificate.yaml | kubectl apply -f -
cat files/cert-manager-letsencrypt-aws-route53-certificate.yaml
```

Output:

```text
namespace/harbor-system created
certificate.certmanager.k8s.io/ingress-cert-production created
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
  acme:
    config:
    - dns01:
        provider: aws-route53
      domains:
      - "*.${MY_DOMAIN}"
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
Name:         ingress-cert-production
Namespace:    harbor-system
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"ingress-cert-production","namespace"...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2019-05-13T13:08:01Z
  Generation:          1
  Resource Version:    7396
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/harbor-system/certificates/ingress-cert-production
  UID:                 22ea0443-7580-11e9-9428-0a68925c47c8
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
    Last Transition Time:  2019-05-13T13:08:01Z
    Message:               Certificate issuance in progress. Temporary certificate issued.
    Reason:                TemporaryCertificate
    Status:                False
    Type:                  Ready
Events:
  Type    Reason              Age   From          Message
  ----    ------              ----  ----          -------
  Normal  Generated           1s    cert-manager  Generated new private key
  Normal  GenerateSelfSigned  1s    cert-manager  Generated temporary self signed certificate
  Normal  OrderCreated        1s    cert-manager  Created Order resource "ingress-cert-production-20059064"
```

The Kubernetes "secret" should contain the certificates:

```bash
kubectl describe secret ingress-cert-${LETSENCRYPT_ENVIRONMENT} -n harbor-system
```

Output:

```text
Name:         ingress-cert-production
Namespace:    harbor-system
Labels:       certmanager.k8s.io/certificate-name=ingress-cert-production
Annotations:  certmanager.k8s.io/alt-names: *.mylabs.dev
              certmanager.k8s.io/common-name: *.mylabs.dev
              certmanager.k8s.io/ip-sans:
              certmanager.k8s.io/issuer-kind: ClusterIssuer
              certmanager.k8s.io/issuer-name: letsencrypt-production-dns

Type:  kubernetes.io/tls

Data
====
ca.crt:   0 bytes
tls.crt:  969 bytes
tls.key:  1679 bytes
```

Clone the repository with Harbor Helm Charts:

```bash
test -d tmp || mkdir tmp
cd tmp
git clone --quiet https://github.com/goharbor/harbor-helm
cd harbor-helm
git checkout --quiet v1.0.1
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
LAST DEPLOYED: Mon May 13 15:08:17 2019
NAMESPACE: harbor-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                         DATA  AGE
harbor-harbor-adminserver    39    2m18s
harbor-harbor-chartmuseum    24    2m18s
harbor-harbor-clair          1     2m18s
harbor-harbor-core           1     2m18s
harbor-harbor-jobservice     1     2m18s
harbor-harbor-notary-server  5     2m18s
harbor-harbor-registry       2     2m18s

==> v1/Deployment
NAME                         READY  UP-TO-DATE  AVAILABLE  AGE
harbor-harbor-adminserver    1/1    1           1          2m18s
harbor-harbor-chartmuseum    1/1    1           1          2m18s
harbor-harbor-clair          1/1    1           1          2m18s
harbor-harbor-core           1/1    1           1          2m18s
harbor-harbor-jobservice     1/1    1           1          2m18s
harbor-harbor-notary-server  1/1    1           1          2m18s
harbor-harbor-notary-signer  1/1    1           1          2m18s
harbor-harbor-portal         1/1    1           1          2m18s
harbor-harbor-registry       1/1    1           1          2m18s

==> v1/Pod(related)
NAME                                          READY  STATUS   RESTARTS  AGE
harbor-harbor-adminserver-786c447c97-rjrsw    1/1    Running  1         2m18s
harbor-harbor-chartmuseum-dbcb6c5db-sqlxw     1/1    Running  0         2m18s
harbor-harbor-clair-6cb966575d-7r9ps          1/1    Running  1         2m18s
harbor-harbor-core-5f48d9f4b7-vcnlj           1/1    Running  1         2m18s
harbor-harbor-database-0                      1/1    Running  0         2m18s
harbor-harbor-jobservice-5bf7cd67d9-5zwrr     1/1    Running  1         2m18s
harbor-harbor-notary-server-68c9dc9989-stgkm  1/1    Running  1         2m18s
harbor-harbor-notary-signer-79cfc45c4c-gn9zc  1/1    Running  1         2m18s
harbor-harbor-portal-5c57c5dfcb-6mdt7         1/1    Running  0         2m18s
harbor-harbor-redis-0                         1/1    Running  0         2m18s
harbor-harbor-registry-57d7f87c44-bphcx       2/2    Running  0         2m18s

==> v1/Secret
NAME                       TYPE    DATA  AGE
harbor-harbor-adminserver  Opaque  4     2m18s
harbor-harbor-chartmuseum  Opaque  1     2m18s
harbor-harbor-core         Opaque  4     2m18s
harbor-harbor-database     Opaque  1     2m18s
harbor-harbor-jobservice   Opaque  1     2m18s
harbor-harbor-registry     Opaque  1     2m18s

==> v1/Service
NAME                         TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
harbor-harbor-adminserver    ClusterIP  10.100.58.52    <none>       80/TCP             2m18s
harbor-harbor-chartmuseum    ClusterIP  10.100.207.7    <none>       80/TCP             2m18s
harbor-harbor-clair          ClusterIP  10.100.167.215  <none>       6060/TCP           2m18s
harbor-harbor-core           ClusterIP  10.100.254.88   <none>       80/TCP             2m18s
harbor-harbor-database       ClusterIP  10.100.5.179    <none>       5432/TCP           2m18s
harbor-harbor-jobservice     ClusterIP  10.100.37.46    <none>       80/TCP             2m18s
harbor-harbor-notary-server  ClusterIP  10.100.123.177  <none>       4443/TCP           2m18s
harbor-harbor-notary-signer  ClusterIP  10.100.248.92   <none>       7899/TCP           2m18s
harbor-harbor-portal         ClusterIP  10.100.178.85   <none>       80/TCP             2m18s
harbor-harbor-redis          ClusterIP  10.100.122.122  <none>       6379/TCP           2m18s
harbor-harbor-registry       ClusterIP  10.100.148.242  <none>       5000/TCP,8080/TCP  2m18s

==> v1/StatefulSet
NAME                    READY  AGE
harbor-harbor-database  1/1    2m18s
harbor-harbor-redis     1/1    2m18s

==> v1beta1/Ingress
NAME                   HOSTS                              ADDRESS        PORTS    AGE
harbor-harbor-ingress  core.mylabs.dev,notary.mylabs.dev  35.156.37.162  80, 443  2m18s


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
Address:          35.156.37.162
Default backend:  default-http-backend:80 (<none>)
TLS:
  ingress-cert-production terminates core.mylabs.dev
  ingress-cert-production terminates notary.mylabs.dev
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
  nginx.ingress.kubernetes.io/ssl-redirect:     true
  ingress.kubernetes.io/proxy-body-size:        0
  ingress.kubernetes.io/ssl-redirect:           true
  nginx.ingress.kubernetes.io/proxy-body-size:  0
Events:
  Type    Reason  Age    From                      Message
  ----    ------  ----   ----                      -------
  Normal  CREATE  2m21s  nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
  Normal  UPDATE  96s    nginx-ingress-controller  Ingress harbor-system/harbor-harbor-ingress
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
            03:f3:01:ae:f9:4e:a1:eb:a4:64:0e:b9:7f:13:83:ea:e5:d0
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = US, O = Let's Encrypt, CN = Let's Encrypt Authority X3
        Validity
            Not Before: May 13 12:09:40 2019 GMT
            Not After : Aug 11 12:09:40 2019 GMT
        Subject: CN = *.mylabs.dev
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
...
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Subject Key Identifier:
                AB:FC:86:C1:D9:24:72:3C:FD:97:22:B0:44:EF:65:9F:DB:83:A3:D1
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

Open the [https://core.mylabs.dev](https://core.mylabs.dev):

![Harbor login page](./harbor_login_page.png "Harbor login page")

Log in:

* User: `admin`
* Password: `admin`

You should see the Web UI:

![Harbor](./harbor_projects.png "Harbor")
