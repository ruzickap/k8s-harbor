# Clean-up

![Clean-up](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/cleanup.svg?sanitize=true
"Clean-up")

-----

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

Remove Nginx and cert-manager:

```bash
helm delete --purge cert-manager
kubectl delete -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml --wait=false
kubectl delete namespace cert-manager --wait=false
helm delete --purge nginx-ingress
kubectl delete namespace nginx-ingress-system --wait=false
kubectl delete namespace mytest --wait=false
```

Remove Helm:

```bash
helm reset
```

Remove EKS cluster:

```bash
eksctl delete cluster --name=${USER}-k8s-harbor --wait
```

Output:

```text
[ℹ]  using region eu-central-1
[ℹ]  deleting EKS cluster "pruzicka-k8s-harbor"
[✔]  kubeconfig has been updated
[ℹ]  2 sequential tasks: { delete nodegroup "ng-d5daf6c0", delete cluster control plane "pruzicka-k8s-harbor" }
[ℹ]  will delete stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-d5daf6c0"
[ℹ]  waiting for stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-d5daf6c0" to get deleted
[ℹ]  will delete stack "eksctl-pruzicka-k8s-harbor-cluster"
[ℹ]  waiting for stack "eksctl-pruzicka-k8s-harbor-cluster" to get deleted
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
rm -rf ~/.docker/
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi --force $(docker images -q)
```

Remove `tmp` directory:

```bash
rm -rf tmp
```

Remove Helm plugin:

```bash
helm plugin remove push
```
