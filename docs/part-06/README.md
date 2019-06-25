# Harbor and Helm charts

YouTube video: [https://youtu.be/XSszSd-TTCQ](https://youtu.be/XSszSd-TTCQ)

## Upload Helm Chart using Web GUI

Download the compressed Helm Chart of Rook:

```bash
wget https://charts.rook.io/release/rook-ceph-v1.0.0.tgz -O rook-ceph-v1.0.0.tgz
```

Output:

```text
--2019-06-25 10:12:31--  https://charts.rook.io/release/rook-ceph-v1.0.0.tgz
Resolving charts.rook.io (charts.rook.io)... 13.32.100.58, 13.32.100.161, 13.32.100.8, ...
Connecting to charts.rook.io (charts.rook.io)|13.32.100.58|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 6246 (6.1K) [application/x-tar]
Saving to: ‘rook-ceph-v1.0.0.tgz’

rook-ceph-v1.0.0.tgz    100%[============================>]   6.10K  --.-KB/s    in 0s

2019-06-25 10:12:31 (99.3 MB/s) - ‘rook-ceph-v1.0.0.tgz’ saved [6246/6246]
```

Upload manually the `rook-ceph-v1.0.0.tgz` to Harbor by clicking on

Projects -> `library` -> Helm Chart -> UPLOAD -> `rook-ceph-v1.0.0.tgz`

Here is the API call:

```bash
curl -s -X POST -u "admin:admin" "https://harbor.${MY_DOMAIN}/api/chartrepo/my_project/charts" \
  -H "Content-Type: multipart/form-data" \
  -F "chart=@rook-ceph-v1.0.0.tgz;type=application/x-yaml" \
| jq "."
```

Output:

```json
{
  "saved": true
}
```

## Upload Helm Chart using CLI

Add helm repository as unprivileged user:

```bash
helm repo add --username aduser05 --password admin my_project_helm_repo https://harbor.mylabs.dev/chartrepo/my_project
```

Output:

```text
"my_project_helm_repo" has been added to your repositories
```

Check the list of Helm repositories:

```bash
helm repo list
```

Output:

```text
NAME                    URL
stable                  https://kubernetes-charts.storage.googleapis.com
local                   http://127.0.0.1:8879/charts
harbor                  https://helm.goharbor.io
jetstack                https://charts.jetstack.io
appscode                https://charts.appscode.com/stable/
my_project_helm_repo    https://harbor.mylabs.dev/chartrepo/my_project
```

Check the content of the `my_project_helm_repo` repository:

```bash
helm search -l my_project_helm_repo
```

Output:

```text
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
my_project_helm_repo/rook-ceph  v1.0.0                          File, Block, and Object Storage Services for your Cloud-N...
```

Clone `harbor-helm` repository containing Helm chart of Harbor:

```bash
git clone https://github.com/goharbor/harbor-helm.git
git -C harbor-helm checkout v1.1.1
```

See the Helm chart content:

```bash
ls -l ./harbor-helm/
```

Output:

```text
total 120
drwxrwxr-x  2 pruzicka pruzicka    36 Jun 25 10:14 cert
-rw-rw-r--  1 pruzicka pruzicka   502 Jun 25 10:14 Chart.yaml
-rw-rw-r--  1 pruzicka pruzicka   577 Jun 25 10:14 CONTRIBUTING.md
drwxrwxr-x  3 pruzicka pruzicka    63 Jun 25 10:14 docs
-rw-rw-r--  1 pruzicka pruzicka 11357 Jun 25 10:14 LICENSE
-rw-rw-r--  1 pruzicka pruzicka 83718 Jun 25 10:14 README.md
drwxrwxr-x 13 pruzicka pruzicka   206 Jun 25 10:14 templates
-rw-rw-r--  1 pruzicka pruzicka 14092 Jun 25 10:14 values.yaml
```

Push the `harbor-helm` to the `my_project_helm_repo` project in Harbor":

```bash
helm push --username aduser05 --password admin ./harbor-helm/ my_project_helm_repo
```

Output:

```text
Pushing harbor-1.1.1.tgz to my_project_helm_repo...
Done.
```

Harbor Project Helm Charts:

![Harbor Project Helm Charts](./harbor_project_helm_charts.png
"Harbor Project Helm Charts")

## Upload signed Helm Chart using CLI

![GnuPG logo](https://upload.wikimedia.org/wikipedia/commons/6/61/Gnupg_logo.svg
"GnuPG logo")

Create GPG key in `.gnupg` directory:

```bash
export GNUPGHOME=$PWD/.gnupg
mkdir ${GNUPGHOME} && chmod 0700 $PWD/.gnupg

cat > ${GNUPGHOME}/my_gpg_key << EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: Helm User
Name-Comment: User
Name-Email: my_helm_user@${MY_DOMAIN}
Expire-Date: 0
%no-protection
%commit
EOF

gpg2 --verbose --batch --gen-key ${GNUPGHOME}/my_gpg_key
```

Output:

```text
gpg: keybox '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/pubring.kbx' created
gpg: Generating a basic OpenPGP key
gpg: no running gpg-agent - starting '/usr/bin/gpg-agent'
gpg: waiting for the agent to come up ... (5s)
gpg: connection to agent established
gpg: writing self signature
gpg: RSA/SHA256 signature from: "6CE5FBFC0ACEF9D1 [?]"
gpg: writing key binding signature
gpg: RSA/SHA256 signature from: "6CE5FBFC0ACEF9D1 [?]"
gpg: RSA/SHA256 signature from: "F4BBFED75D895C46 [?]"
gpg: writing public key to '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/pubring.kbx'
gpg: /home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/trustdb.gpg: trustdb created
gpg: using pgp trust model
gpg: key 6CE5FBFC0ACEF9D1 marked as ultimately trusted
gpg: directory '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d' created
gpg: writing to '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/CC11B974DC5DBB4AFD63D8F96CE5FBFC0ACEF9D1.rev'
gpg: RSA/SHA256 signature from: "6CE5FBFC0ACEF9D1 Helm User (User) <my_helm_user@mylabs.dev>"
gpg: revocation certificate stored as '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/CC11B974DC5DBB4AFD63D8F96CE5FBFC0ACEF9D1.rev'
```

List the GPG secret key:

```bash
gpg2 --list-secret-keys
```

Output:

```text
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/pubring.kbx
------------------------------------------------------------
sec   rsa2048 2019-06-25 [SCEA]
      CC11B974DC5DBB4AFD63D8F96CE5FBFC0ACEF9D1
uid           [ultimate] Helm User (User) <my_helm_user@mylabs.dev>
ssb   rsa2048 2019-06-25 [SEA]
```

Export private GPG key into `.gnupg/secring.gpg`, because Helm doesn't
support GnuPG 2.1:

```bash
gpg2 --export-secret-keys > ${GNUPGHOME}/secring.gpg
```

Output:

```text
gpg: starting migration from earlier GnuPG versions
gpg: porting secret keys from '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/secring.gpg' to gpg-agent
gpg: migration succeeded
```

Download and unpack Gitea Helm chart:

```bash
git clone --quiet https://github.com/jfelten/gitea-helm-chart gitea
git -C ./gitea/ checkout --quiet 8c9adad
```

Create signed Helm package:

```bash
helm package --sign --key "my_helm_user@${MY_DOMAIN}" --keyring ${GNUPGHOME}/secring.gpg --destination . ./gitea/
```

Output:

```text
Successfully packaged chart and saved it to: /home/pruzicka/data/github/k8s-harbor/tmp/gitea-1.6.1.tgz
```

There should be 2 files in current directory - the archive with the Helm Chart
and **provenance** file:

```bash
ls -la gitea*tgz*
```

Output:

```text
-rw-rw-r-- 1 pruzicka pruzicka 20390 Jun 25 10:16 gitea-1.6.1.tgz
-rwxr-xr-x 1 pruzicka pruzicka   966 Jun 25 10:16 gitea-1.6.1.tgz.prov
```

See the provenance file:

```bash
cat gitea-1.6.1.tgz.prov && echo
```

Output:

```text
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

appVersion: 1.6.1
description: Git with a cup of tea
icon: https://docs.gitea.io/images/gitea.png
keywords:
- - git
- - issue tracker
- - code review
- - wiki
- - gitea
- - gogs
maintainers:
- - email: john.felten@gmail.com
  name: John Felten
name: gitea
sources:
- - https://github.com/go-gitea/gitea
- - https://hub.docker.com/r/gitea/gitea/
version: 1.6.1

...
files:
  gitea-1.6.1.tgz: sha256:9d897da1e11dd56a24a2fb18d235846f0c78a8359d8e21f666bcbcadebea434f
-----BEGIN PGP SIGNATURE-----
...
-----END PGP SIGNATURE-----
```

Upload the signed Helm package to Harbor public project `library`:

Upload manually Gitea Helm Chart to Harbor by clicking on:

Projects -> library -> Helm Chart -> UPLOAD
-> `gitea-1.6.1.tgz` + `gitea-1.6.1.tgz.prov`

You can also do the same using the Harbor API:

```bash
curl -s -u "aduser06:admin" -X POST "https://harbor.${MY_DOMAIN}/api/chartrepo/library/charts" \
  -H "Content-Type: multipart/form-data" \
  -F "chart=@gitea-1.6.1.tgz;type=application/x-compressed-tar" \
  -F "prov=@gitea-1.6.1.tgz.prov" \
| jq "."
```

Output:

```json
{
  "saved": true
}
```

## Use Harbor Helm Chart repository

![ChartMuseum logo](https://raw.githubusercontent.com/helm/chartmuseum/0cfa25360682f66069d595fb0ede0fcc69bad41f/logo.png
"ChartMuseum logo")

Add the public "library" Helm Chart repository:

```bash
helm repo add library https://harbor.mylabs.dev/chartrepo/library
```

Output:

```text
"library" has been added to your repositories
```

Check the Helm Repository list:

```bash
helm repo list | grep library
```

Output:

```text
library                 https://harbor.mylabs.dev/chartrepo/library
```

Install Gitea using Helm Chart stored in Harbor:

```bash
helm install --wait --name gitea --namespace gitea-system library/gitea \
  --set ingress.enabled=true \
  --set ingress.tls[0].secretName=ingress-cert-${LETSENCRYPT_ENVIRONMENT} \
  --set ingress.tls[0].hosts[0]=gitea.${MY_DOMAIN} \
  --set service.http.externalHost=gitea.${MY_DOMAIN} \
  --set config.disableInstaller=true
```

Output:

```text
NAME:   gitea
E0625 10:17:15.488085    6412 portforward.go:372] error copying from remote stream to local connection: readfrom tcp4 127.0.0.1:38255->127.0.0.1:39576: write tcp4 127.0.0.1:38255->127.0.0.1:39576: write: broken pipe
LAST DEPLOYED: Tue Jun 25 10:17:13 2019
NAMESPACE: gitea-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME         DATA  AGE
gitea-gitea  1     2s

==> v1/Pod(related)
NAME                         READY  STATUS    RESTARTS  AGE
gitea-gitea-f9fd8cb4b-8p58m  0/3    Init:0/1  0         2s

==> v1/Secret
NAME      TYPE    DATA  AGE
gitea-db  Opaque  1     2s

==> v1/Service
NAME              TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)   AGE
gitea-gitea-http  ClusterIP  10.100.19.173  <none>       3000/TCP  2s
gitea-gitea-ssh   ClusterIP  10.100.134.45  <none>       22/TCP    2s

==> v1beta1/Deployment
NAME         READY  UP-TO-DATE  AVAILABLE  AGE
gitea-gitea  0/1    1           0          2s

==> v1beta1/Ingress
NAME                HOSTS             ADDRESS  PORTS  AGE
gitea-giteaingress  gitea.mylabs.dev  80, 443  2s


NOTES:
1. Connect to your Gitea web URL by running:


  Ingress is enabled for this chart deployment.  Please access the web UI at gitea.mylabs.dev

2. Connect to your Gitea ssh port:

  export POD_NAME=$(kubectl get pods --namespace gitea-system -l "app=gitea-gitea" -o jsonpath="{.items[0].metadata.name}")
  echo http://127.0.0.1:8080/
  kubectl port-forward $POD_NAME 8022:22
```

If you open the [https://gitea.mylabs.dev](https://gitea.mylabs.dev) you should
see the initial Gitea page:

![Gitea main page](./gitea_screenshot.png "Gitea main page")
