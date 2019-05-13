# Harbor and Helm charts

YouTube video: [https://youtu.be/XSszSd-TTCQ](https://youtu.be/XSszSd-TTCQ)

## Upload Helm Chart using Web GUI

Download the compressed Helm Chart of Rook:

```bash
wget --quiet https://charts.rook.io/release/rook-ceph-v1.0.0.tgz -O rook-ceph-v1.0.0.tgz
```

Upload manually the `rook-ceph-v1.0.0.tgz` to Harbor by clicking on

Projects -> library -> Helm Chart -> UPLOAD -> `rook-ceph-v1.0.0.tgz`

Here is the API call

```bash
curl -s -X POST -u "admin:admin" "https://core.${MY_DOMAIN}/api/chartrepo/library/charts" \
  -H "Content-Type: multipart/form-data" \
  -F "chart=@rook-ceph-v1.0.0.tgz;type=application/x-yaml" \
| jq
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
helm repo add --username aduser05 --password admin my_project_helm_repo https://core.mylabs.dev/chartrepo/my_project
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
jetstack                https://charts.jetstack.io
my_project_helm_repo    https://core.mylabs.dev/chartrepo/my_project
library                 https://core.mylabs.dev/chartrepo/library
```

See the Helm chart content:

```bash
ls -l ./harbor-helm/
```

Output:

```text
total 52
-rw-rw-r--  1 pruzicka pruzicka   502 May 13 15:08 Chart.yaml
-rw-rw-r--  1 pruzicka pruzicka   577 May 13 15:08 CONTRIBUTING.md
drwxrwxr-x  3 pruzicka pruzicka    63 May 13 15:08 docs
-rw-rw-r--  1 pruzicka pruzicka 11357 May 13 15:08 LICENSE
-rw-rw-r--  1 pruzicka pruzicka 20336 May 13 15:08 README.md
drwxrwxr-x 14 pruzicka pruzicka   225 May 13 15:08 templates
-rw-rw-r--  1 pruzicka pruzicka 11711 May 13 15:08 values.yaml
```

Push the `harbor-helm` to the `my_project_helm_repo` project in Harbor":

```bash
helm push --username aduser05 --password admin ./harbor-helm/ my_project_helm_repo
```

Output:

```text
Pushing harbor-1.0.1.tgz to my_project_helm_repo...
Done.
```

## Upload signed Helm Chart using CLI

Create GPG key in `.gnupg/` directory:

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
gpg: RSA/SHA256 signature from: "0A3D3EB0B6D9AA6D [?]"
gpg: writing key binding signature
gpg: RSA/SHA256 signature from: "0A3D3EB0B6D9AA6D [?]"
gpg: RSA/SHA256 signature from: "8622040B57DCC9EE [?]"
gpg: writing public key to '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/pubring.kbx'
gpg: /home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/trustdb.gpg: trustdb created
gpg: using pgp trust model
gpg: key 0A3D3EB0B6D9AA6D marked as ultimately trusted
gpg: directory '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d' created
gpg: writing to '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/07C7E72D3B8C71FA5C943EE40A3D3EB0B6D9AA6D.rev'
gpg: RSA/SHA256 signature from: "0A3D3EB0B6D9AA6D Helm User (User) <my_helm_user@mylabs.dev>"
gpg: revocation certificate stored as '/home/pruzicka/data/github/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/07C7E72D3B8C71FA5C943EE40A3D3EB0B6D9AA6D.rev'
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
sec   rsa2048 2019-05-13 [SCEA]
      07C7E72D3B8C71FA5C943EE40A3D3EB0B6D9AA6D
uid           [ultimate] Helm User (User) <my_helm_user@mylabs.dev>
ssb   rsa2048 2019-05-13 [SEA]
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
-rw-rw-r-- 1 pruzicka pruzicka 20390 May 13 15:11 gitea-1.6.1.tgz
-rwxr-xr-x 1 pruzicka pruzicka   966 May 13 15:11 gitea-1.6.1.tgz.prov
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
  gitea-1.6.1.tgz: sha256:4bf1923d6c69e6b3d303f0bd79046acfb0e9891617563a7ad169477d107ebb49
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
curl -s -u "aduser06:admin" -X POST "https://core.${MY_DOMAIN}/api/chartrepo/library/charts" \
  -H "Content-Type: multipart/form-data" \
  -F "chart=@gitea-1.6.1.tgz;type=application/x-compressed-tar" \
  -F "prov=@gitea-1.6.1.tgz.prov" \
| jq
```

Output:

```json
{
  "saved": true
}
```

## Use Harbor Helm Chart repository

Add the public "library" Helm Chart repository:

```bash
helm repo add library https://core.mylabs.dev/chartrepo/library
```

Output:

```text
"library" has been added to your repositories
```

Refresh the Helm repositories:

```bash
helm repo update
```

Output:

```text
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "library" chart repository
...Successfully got an update from the "my_project_helm_repo" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
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
LAST DEPLOYED: Mon May 13 15:11:55 2019
NAMESPACE: gitea-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME         DATA  AGE
gitea-gitea  1     3s

==> v1/Pod(related)
NAME                         READY  STATUS    RESTARTS  AGE
gitea-gitea-f9fd8cb4b-hm587  0/3    Init:0/1  0         2s

==> v1/Secret
NAME      TYPE    DATA  AGE
gitea-db  Opaque  1     3s

==> v1/Service
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
gitea-gitea-http  ClusterIP  10.100.121.170  <none>       3000/TCP  3s
gitea-gitea-ssh   ClusterIP  10.100.54.65    <none>       22/TCP    3s

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
