# Harbor and container images

Few more samples how you can work with container images in Harbor.

## Upload docker image

Create simple Docker image

```bash
echo admin | docker login --username aduser05 --password-stdin harbor.${MY_DOMAIN}
```

Output:

```text
WARNING! Your password will be stored unencrypted in /home/pruzicka/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

Download `kuard` docker image:

```bash
docker pull gcr.io/kuar-demo/kuard-amd64:blue
```

Output:

```text
blue: Pulling from kuar-demo/kuard-amd64
8e402f1a9c57: Pull complete
8df70f469ef0: Pull complete
Digest: sha256:1ecc9fb2c871302fdb57a25e0c076311b7b352b0a9246d442940ca8fb4efe229
Status: Downloaded newer image for gcr.io/kuar-demo/kuard-amd64:blue
```

Tag `kuard` with customized name to push to the private repository in Harbor:

```bash
docker tag gcr.io/kuar-demo/kuard-amd64:blue harbor.${MY_DOMAIN}/my_project/kuard-amd64:blue
```

List all images:

```bash
docker images
```

Output:

```text{3}
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
gcr.io/kuar-demo/kuard-amd64               blue                1db936caa6ac        3 months ago        23MB
harbor.mylabs.dev/my_project/kuard-amd64   blue                1db936caa6ac        3 months ago        23MB
```

Push docker image to Harbor:

```bash
docker push harbor.${MY_DOMAIN}/my_project/kuard-amd64:blue
```

Output:

```text
The push refers to repository [harbor.mylabs.dev/my_project/kuard-amd64]
656e9c47289e: Pushed
bcf2f368fe23: Pushed
blue: digest: sha256:1ecc9fb2c871302fdb57a25e0c076311b7b352b0a9246d442940ca8fb4efe229 size: 739
```

It should be visible in the Harbor UI:

![Container image in Harbor UI](./harbor_container_image.png
"Container image in Harbor UI")

## Signed container image

YouTube video: [https://youtu.be/pPklSTJZY2E](https://youtu.be/pPklSTJZY2E)

![Notary](https://raw.githubusercontent.com/theupdateframework/notary/97a2d690658937fea3b65b4494bd5c3a75558d08/docs/images/notary-blk.svg?sanitize=true
"Notary")

Tag the `kuard` image to be pulled to Harbor `library` project:

```bash
docker tag gcr.io/kuar-demo/kuard-amd64:blue harbor.${MY_DOMAIN}/library/kuard-amd64:blue
```

Push there the image:

```bash
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://notary.${MY_DOMAIN}
export DOCKER_CONTENT_TRUST_REPOSITORY_PASSPHRASE="mypassphrase123"
export DOCKER_CONTENT_TRUST_ROOT_PASSPHRASE="rootpassphrase123"
docker push harbor.${MY_DOMAIN}/library/kuard-amd64:blue
unset DOCKER_CONTENT_TRUST
```

Output:

```text{5}
The push refers to repository [harbor.mylabs.dev/library/kuard-amd64]
656e9c47289e: Mounted from my_project/kuard-amd64
bcf2f368fe23: Mounted from my_project/kuard-amd64
blue: digest: sha256:1ecc9fb2c871302fdb57a25e0c076311b7b352b0a9246d442940ca8fb4efe229 size: 739
Signing and pushing trust metadata
Finished initializing "harbor.mylabs.dev/library/kuard-amd64"
Successfully signed harbor.mylabs.dev/library/kuard-amd64:blue
```

You should be able to see the signed container image in the Harbor web
interface:

![Signed container image](./harbor_signed_container_image.png "Signed container image")

Install [Notary](https://github.com/theupdateframework/notary) which can show
you the signature form "Harbor":

```bash
sudo curl -sL https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64 -o /usr/local/bin/notary
sudo chmod a+x /usr/local/bin/notary
```

Access Notary using the standard client:

```bash
notary -s https://notary.${MY_DOMAIN} list harbor.${MY_DOMAIN}/library/kuard-amd64
```

Output:

```text
NAME    DIGEST                                                              SIZE (BYTES)    ROLE
----    ------                                                              ------------    ----
blue    1ecc9fb2c871302fdb57a25e0c076311b7b352b0a9246d442940ca8fb4efe229    739             targets
```

## Vulnerability scan

YouTube video: [https://youtu.be/K4tJ6B2cGR4](https://youtu.be/K4tJ6B2cGR4)

![Clair logo](https://cloud.githubusercontent.com/assets/343539/21630811/c5081e5c-d202-11e6-92eb-919d5999c77a.png
"Clair logo")

Wait for Clair to finish updating the "Vulnerability database" (it may take a
long time).

Wait for Clair to update the vulnerability data:

```bash
CLAIR_POD=$(kubectl get pods -l "app=harbor,component=clair" -n harbor-system -o jsonpath="{.items[0].metadata.name}")
while ! kubectl logs -n harbor-system ${CLAIR_POD} | grep "update finished"; do echo -n ". "; sleep 10; done
```

Output:

```json
{"Event":"update finished","Level":"info","Location":"updater.go:223","Time":"2019-07-19 10:15:24.517724"}
```

See if "Vulnerability database" was successfully updated using API:

```bash
curl -s -u "admin:admin" "https://harbor.${MY_DOMAIN}/api/systeminfo" | jq ".clair_vulnerability_status"
```

Output:

```json
{
  "overall_last_update": 1563531324,
  "details": [
    {
      "namespace": "debian",
      "last_update": 1563531324
    },
    {
      "namespace": "alpine",
      "last_update": 1563531324
    },
    {
      "namespace": "ubuntu",
      "last_update": 1563531324
    },
    {
      "namespace": "oracle",
      "last_update": 1563531324
    },
    {
      "namespace": "centos",
      "last_update": 1563531324
    }
  ]
}
```

Scan the image `kuard-amd64:blue` for vulnerabilities (using API):

```bash
curl -u "aduser05:admin" --header "Content-Type: application/json" -X POST "https://harbor.${MY_DOMAIN}/api/repositories/my_project/kuard-amd64/tags/blue/scan"
```

Everything should be "green" - no vulnerability found:

![Scanned container image in Harbor UI](./harbor_scanned_container_image.png
"Scanned container image in Harbor UI")

Let's download popular web server [Nginx](https://en.wikipedia.org/wiki/Nginx)
based on Debian Stretch from Docker Hub. The image is is one year old:
[https://hub.docker.com/_/nginx?tab=tags&page=5](https://hub.docker.com/_/nginx?tab=tags&page=5)

```bash
docker pull nginx:1.13.12
```

Output:

```text
1.13.12: Pulling from library/nginx
f2aa67a397c4: Pull complete
3c091c23e29d: Pull complete
4a99993b8636: Pull complete
Digest: sha256:b1d09e9718890e6ebbbd2bc319ef1611559e30ce1b6f56b2e3b479d9da51dc35
Status: Downloaded newer image for nginx:1.13.12
```

Tag `nginx` to push to the private repository in Harbor:

```bash
docker tag nginx:1.13.12 harbor.${MY_DOMAIN}/my_project/nginx:1.13.12
```

List all images:

```bash
docker images
```

Output:

```text{6}
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
gcr.io/kuar-demo/kuard-amd64               blue                1db936caa6ac        3 months ago        23MB
harbor.mylabs.dev/library/kuard-amd64      blue                1db936caa6ac        3 months ago        23MB
harbor.mylabs.dev/my_project/kuard-amd64   blue                1db936caa6ac        3 months ago        23MB
nginx                                      1.13.12             ae513a47849c        14 months ago       109MB
harbor.mylabs.dev/my_project/nginx         1.13.12             ae513a47849c        14 months ago       109MB
```

Push `nginx` docker image to Harbor:

```bash
docker push harbor.${MY_DOMAIN}/my_project/nginx:1.13.12
```

Output:

```text
The push refers to repository [harbor.mylabs.dev/my_project/nginx]
7ab428981537: Pushed
82b81d779f83: Pushed
d626a8ad97a1: Pushed
1.13.12: digest: sha256:e4f0474a75c510f40b37b6b7dc2516241ffa8bde5a442bde3d372c9519c84d90 size: 948
```

Scan the image for vulnerabilities:

```bash
curl -u "aduser06:admin" --header "Content-Type: application/json" -X POST "https://harbor.${MY_DOMAIN}/api/repositories/my_project%2Fnginx/tags/1.13.12/scan"
```

You should see many vulnerabilities in the container image:

![Scanned container image with vulnerabilities](./harbor_scanned_container_image_with_vulnerabilities.png
"Scanned container image with vulnerabilities")

Vulnerability list for container image:

![Vulnerability list for container image](./harbor_container_image_vulnerability_list.png
"Vulnerability list for container image")

## Replication

YouTube video: [https://youtu.be/1NPlzrm5ozE](https://youtu.be/1NPlzrm5ozE)

You can configure replication form other registries to replicate helm charts or
containers.

Create new Registry Endpoint:

```bash
curl -X POST -H "Content-Type: application/json" -u "admin:admin" "https://harbor.${MY_DOMAIN}/api/registries" -d \
"{
  \"name\": \"Docker Hub\",
  \"type\": \"docker-hub\",
  \"url\": \"https://hub.docker.com\",
  \"description\": \"Docker Hub Registry Endpoint\"
}"
```

In the Web GUI you should see:

![Harbor Registries](./harbor_registries.png "Harbor Registries")

Create new Replication Rule:

```bash
curl -X POST -H "Content-Type: application/json" -u "admin:admin" "https://harbor.${MY_DOMAIN}/api/replication/policies" -d \
"{
  \"name\": \"Replication of paulbouwer/hello-kubernetes\",
  \"type\": \"docker-hub\",
  \"url\": \"https://hub.docker.com\",
  \"description\": \"Replication Rule for paulbouwer/hello-kubernetes\",
  \"enabled\": true,
  \"src_registry\": {
    \"id\": 1
  },
  \"dest_namespace\": \"library\",
  \"filters\": [{
    \"type\": \"name\",
    \"value\": \"paulbouwer/hello-kubernetes\"
  }],
  \"trigger\": {
    \"type\": \"manual\"
  }
}"
```

Start the replication:

```bash
curl -X POST -H "Content-Type: application/json" -u "admin:admin" "https://harbor.${MY_DOMAIN}/api/replication/executions" -d "{ \"policy_id\": 1 }"
```

Prepare ingress for running the application `hello-kubernetes`:

```bash
export APP=hello-kubernetes
envsubst < ../files/app_ingress.yaml | kubectl create -f -
```

Output:

```text
ingress.extensions/hello-kubernetes created
```

The Replications and Execution tabs looks like:

![Harbor Replications](./harbor_replications.png "Harbor Replications")

![Harbor Replication Execution](./harbor_replication_execution.png
"Harbor Replication Execution")

![Harbor Project Repository list](./harbor_projects_repositories_list.png
"Harbor Project Repository list")

Let's run the replicated docker image:

```bash
kubectl run hello-kubernetes --image=harbor.${MY_DOMAIN}/library/hello-kubernetes:1.5 --port=8080 --expose=true --labels="app=hello-kubernetes" -n mytest
```

Output:

```text
kubectl run --generator=deployment/apps.v1 is DEPRECATED and will be removed in a future version. Use kubectl run --generator=run-pod/v1 or kubectl create instead.
service/hello-kubernetes created
deployment.apps/hello-kubernetes created
```

Open the web browser with URL: [https://hello-kubernetes.mylabs.dev](https://hello-kubernetes.mylabs.dev)
