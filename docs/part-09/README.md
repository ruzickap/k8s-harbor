# Clean-up

![Clean-up](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/cleanup.svg?sanitize=true
"Clean-up")

-----

Configure `kubeconfig`:

```bash
export MY_DOMAIN="mylabs.dev"
eksctl utils write-kubeconfig --kubeconfig kubeconfig.conf --name=${USER}-k8s-harbor
export KUBECONFIG=${KUBECONFIG:-$PWD/kubeconfig.conf}
```

Remove Windows Server 2016 CloudFormation stack:

```bash
aws cloudformation delete-stack --stack-name eksctl-${USER}-k8s-harbor-cluster-windows-server-2016
```

Remove Gitea:

```bash
helm delete --purge gitea
kubectl delete namespace gitea-system --wait=false
```

Remove Harbor:

```bash
helm delete --purge harbor
kubectl delete namespace harbor-system --wait=false
```

Remove kubed:

```bash
helm delete --purge kubed
```

Remove cert-manager:

```bash
helm delete --purge cert-manager
kubectl delete -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml --wait=false
kubectl delete namespace cert-manager --wait=false
```

Remove Nginx-ingress:

```bash
helm delete --purge nginx-ingress
kubectl delete namespace nginx-ingress-system --wait=false
kubectl delete namespace mytest --wait=false
```

Cleanup + Remove Helm:

```bash
helm repo remove harbor jetstack appscode library
helm reset --remove-helm-home
kubectl delete serviceaccount tiller --namespace kube-system --wait=false
kubectl delete clusterrolebinding tiller-cluster-rule --wait=false
```

Output:

```text
Deleting /home/pruzicka/.helm
Tiller (the Helm server-side component) has been uninstalled from your Kubernetes Cluster.
```

Remove EKS cluster:

```bash
eksctl delete cluster --name=${USER}-k8s-harbor
```

Output:

```text
[ℹ]  using region eu-central-1
[ℹ]  deleting EKS cluster "pruzicka-k8s-harbor"
[✔]  kubeconfig has been updated
[ℹ]  2 sequential tasks: { delete nodegroup "ng-d1b535b2", delete cluster control plane "pruzicka-k8s-harbor" [async] }
[ℹ]  will delete stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-d1b535b2"
[ℹ]  waiting for stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-d1b535b2" to get deleted
[ℹ]  will delete stack "eksctl-pruzicka-k8s-harbor-cluster"
[✔]  all cluster resources were deleted
```

Clean Policy, User, Access Key in AWS:

```bash
# aws route53 delete-hosted-zone --id $(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text)
aws iam detach-user-policy --user-name "${USER}-eks-cert-manager-route53" --policy-arn $(aws iam list-policies --query "Policies[?PolicyName==\`${USER}-AmazonRoute53Domains-cert-manager\`].{ARN:Arn}" --output text)
aws iam delete-policy --policy-arn $(aws iam list-policies --query "Policies[?PolicyName==\`${USER}-AmazonRoute53Domains-cert-manager\`].{ARN:Arn}" --output text)
aws iam delete-access-key --user-name ${USER}-eks-cert-manager-route53 --access-key-id $(aws iam list-access-keys --user-name ${USER}-eks-cert-manager-route53 --query "AccessKeyMetadata[].AccessKeyId" --output text)
aws iam delete-user --user-name ${USER}-eks-cert-manager-route53
```

Docker clean-up:

```bash
test -d ~/.docker/ && rm -rf ~/.docker/
DOCKER_CONTAINERS=$(docker ps -a -q)
[ -n "${DOCKER_CONTAINERS}" ] && docker stop ${DOCKER_CONTAINERS} && docker rm ${DOCKER_CONTAINERS}
DOCKER_IMAGES=$(docker images -q)
[ -n "${DOCKER_IMAGES}" ] && docker rmi --force ${DOCKER_IMAGES}
```

Notary clean-up:

```bash
test -d ~/.notary/ && rm -rf ~/.notary/
```

Docker certificate cleanup if exists:

```bash
rm -rf /etc/docker/certs.d/harbor.${MY_DOMAIN}
```

Remove `tmp` directory:

```bash
rm -rf tmp
```

Remove other files:

```bash
rm demo-magic.sh kubeconfig.conf README.sh &> /dev/null
```
