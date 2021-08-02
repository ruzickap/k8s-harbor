# Harbor and Helm charts

YouTube video: [https://youtu.be/XSszSd-TTCQ](https://youtu.be/XSszSd-TTCQ)

## Add Project

* Go to `Projects`, click on `NEW PROJECT` and create "private"
  `my_project` project.

You can also use the API directly:

```bash{3}
curl -u "admin:admin" -X POST -H "Content-Type: application/json" "https://harbor.${MY_DOMAIN}/api/projects" -d \
"{
  \"project_name\": \"my_project\",
  \"public\": 0
}"
```

Create namespace which will be used later:

```bash
kubectl create namespace mytest
```

## Upload Helm Chart using CLI

Clone `harbor-helm` repository containing Helm chart of Harbor:

```bash
git clone https://github.com/goharbor/harbor-helm.git
git -C harbor-helm checkout v1.1.1
```

See the Helm chart content:

```bash
ls ./harbor-helm/
```

Output:

```text
cert  Chart.yaml  CONTRIBUTING.md  docs  LICENSE  README.md  templates  values.yaml
```

Add the public "library" Helm Chart repository:

```bash
helm repo add library https://harbor.${MY_DOMAIN}/chartrepo/library
```

Output:

```text
"library" has been added to your repositories
```

Push the `harbor-helm` to the `library` project in Harbor":

```bash
helm push --username aduser05 --password admin ./harbor-helm/ library
```

Output:

```text
Pushing harbor-1.1.1.tgz to library...
Done.
```

Check the Helm Repository list:

```bash
helm repo list
```

Output:

```text
NAME            URL
stable          https://kubernetes-charts.storage.googleapis.com
local           http://127.0.0.1:8879/charts
jetstack        https://charts.jetstack.io
appscode        https://charts.appscode.com/stable/
harbor          https://helm.goharbor.io
library         https://harbor.mylabs.dev/chartrepo/library
```

Check the content of the `library` repository:

```bash
helm repo update
helm search -l library/
```

Output:

```text{10}
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "appscode" chart repository
...Successfully got an update from the "library" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete.
NAME            CHART VERSION   APP VERSION     DESCRIPTION
library/harbor  1.1.1           1.8.1           An open source trusted cloud native registry that stores,...
```

Harbor Project Helm Charts:

![Harbor Project Helm Charts](./harbor_project_helm_charts.png
"Harbor Project Helm Charts")

## Upload signed Helm Chart using CLI

Create GPG key in `.gnupg` directory:

```bash{12}
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

```text{17}
gpg: keybox '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/pubring.kbx' created
gpg: Generating a basic OpenPGP key
gpg: no running gpg-agent - starting '/usr/bin/gpg-agent'
gpg: waiting for the agent to come up ... (5s)
gpg: connection to agent established
gpg: writing self signature
gpg: RSA/SHA256 signature from: "6733D8DA847797FE [?]"
gpg: writing key binding signature
gpg: RSA/SHA256 signature from: "6733D8DA847797FE [?]"
gpg: RSA/SHA256 signature from: "C8B680F790B62239 [?]"
gpg: writing public key to '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/pubring.kbx'
gpg: /home/pruzicka/git/k8s-harbor/tmp/.gnupg/trustdb.gpg: trustdb created
gpg: using pgp trust model
gpg: key 6733D8DA847797FE marked as ultimately trusted
gpg: directory '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/openpgp-revocs.d' created
gpg: writing to '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/4DA54853FC984FF42EDD2C9B6733D8DA847797FE.rev'
gpg: RSA/SHA256 signature from: "6733D8DA847797FE Helm User (User) <my_helm_user@mylabs.dev>"
gpg: revocation certificate stored as '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/openpgp-revocs.d/4DA54853FC984FF42EDD2C9B6733D8DA847797FE.rev'
```

List the GPG secret key:

```bash
gpg2 --list-secret-keys
```

Output:

```text{8}
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
/home/pruzicka/git/k8s-harbor/tmp/.gnupg/pubring.kbx
----------------------------------------------------
sec   rsa2048 2019-07-19 [SCEA]
      4DA54853FC984FF42EDD2C9B6733D8DA847797FE
uid           [ultimate] Helm User (User) <my_helm_user@mylabs.dev>
ssb   rsa2048 2019-07-19 [SEA]
```

Export private GPG key into `.gnupg/secring.gpg`, because Helm doesn't
support GnuPG 2.1:

```bash
gpg2 --export-secret-keys > ${GNUPGHOME}/secring.gpg
```

Output:

```text
gpg: starting migration from earlier GnuPG versions
gpg: porting secret keys from '/home/pruzicka/git/k8s-harbor/tmp/.gnupg/secring.gpg' to gpg-agent
gpg: migration succeeded
```

Download and unpack Gitea Helm chart:

```bash
git clone --quiet https://github.com/jfelten/gitea-helm-chart gitea
git -C ./gitea/ checkout --quiet 8c9adad
```

```bash
ls ./gitea/
```

Output:

```text
Chart.yaml  LICENSE  postgres-values.yaml  README.md  templates  values.yaml
```

Create signed Helm package:

```bash
helm package --sign --key "my_helm_user@${MY_DOMAIN}" --keyring ${GNUPGHOME}/secring.gpg --destination . ./gitea/
```

Output:

```text
Successfully packaged chart and saved it to: /home/pruzicka/git/k8s-harbor/tmp/gitea-1.6.1.tgz
```

There should be 2 files in current directory - the archive with the Helm Chart
and **provenance** file:

```bash
ls -la gitea*tgz*
```

Output:

```text
-rw-rw-r-- 1 pruzicka pruzicka 20391 Jul 19 12:27 gitea-1.6.1.tgz
-rwxr-xr-x 1 pruzicka pruzicka   966 Jul 19 12:27 gitea-1.6.1.tgz.prov
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
  gitea-1.6.1.tgz: sha256:f2e1989577cea950226abe714103709dca8574d82b7a0035b32e97f8d956bcae
-----BEGIN PGP SIGNATURE-----
...
-----END PGP SIGNATURE-----
```

Upload the signed Helm package to Harbor public project `library`:

Upload manually Gitea Helm Chart to Harbor by clicking on:

Projects -> library -> Helm Chart -> UPLOAD
-> `gitea-1.6.1.tgz` + `gitea-1.6.1.tgz.prov`

![Harbor Upload Chart Files](./harbor_upload_chart_files.png
"Harbor Upload Chart Files")

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

Install Gitea using Helm Chart stored in Harbor:

```bash
helm repo list | grep -q library || helm repo add library https://harbor.${MY_DOMAIN}/chartrepo/library
helm repo update
helm install --wait --name gitea --namespace gitea-system library/gitea \
  --set ingress.enabled=true \
  --set ingress.tls[0].secretName=ingress-cert-${LETSENCRYPT_ENVIRONMENT} \
  --set ingress.tls[0].hosts[0]=gitea.${MY_DOMAIN} \
  --set service.http.externalHost=gitea.${MY_DOMAIN} \
  --set config.disableInstaller=true
```

Output:

```text{38}
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "appscode" chart repository
...Successfully got an update from the "library" chart repository
...Successfully got an update from the "harbor" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "stable" chart repository
Update Complete.
NAME:   gitea
LAST DEPLOYED: Fri Jul 19 12:34:25 2019
NAMESPACE: gitea-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME         DATA  AGE
gitea-gitea  1     2s

==> v1/Pod(related)
NAME                        READY  STATUS    RESTARTS  AGE
gitea-gitea-5fff4b9c-4k4xq  0/3    Init:0/1  0         2s

==> v1/Secret
NAME      TYPE    DATA  AGE
gitea-db  Opaque  1     2s

==> v1/Service
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
gitea-gitea-http  ClusterIP  10.100.121.156  <none>       3000/TCP  2s
gitea-gitea-ssh   ClusterIP  10.100.181.96   <none>       22/TCP    2s

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
