# Create EKS cluster

![Amazon EKS](https://raw.githubusercontent.com/cncf/landscape/7f5b02ecba914a32912e77fc78e1c54d1c2f98ec/hosted_logos/amazon-eks.svg?sanitize=true
"Amazon EKS")

Before starting with the main content, it's necessary to provision
the [Amazon EKS](https://aws.amazon.com/eks/) in AWS.

Use the `MY_DOMAIN` variable containing domain and `LETSENCRYPT_ENVIRONMENT`
variable.
The `LETSENCRYPT_ENVIRONMENT` variable should be one of:

* `staging` - Let’s Encrypt will create testing certificate (not valid)

* `production` - Let’s Encrypt will create valid certificate (use with care)

```bash
export MY_DOMAIN=${MY_DOMAIN:-mylabs.dev}
export LETSENCRYPT_ENVIRONMENT=${LETSENCRYPT_ENVIRONMENT:-staging}
echo "${MY_DOMAIN} | ${LETSENCRYPT_ENVIRONMENT}"
```

## Prepare the local working environment

::: tip
You can skip these steps if you have all the required software already
installed.
:::

Install necessary software:

```bash
test -x /usr/bin/apt && \
apt update -qq && \
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli curl docker.io freerdp-x11 gettext-base git gnupg2 jq ldap-utils openssh-client python3-pip sudo wget > /dev/null && \
pip3 install --quiet ansible boto3 pywinrm
```

Install [kubectl](https://github.com/kubernetes/kubectl) binary:

```bash
if [ ! -x /usr/local/bin/kubectl ]; then
  sudo curl -s -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  sudo chmod a+x /usr/local/bin/kubectl
fi
```

Install [eksctl](https://eksctl.io/):

```bash
if [ ! -x /usr/local/bin/eksctl ]; then
  curl -s -L "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_Linux_amd64.tar.gz" | sudo tar xz -C /usr/local/bin/
fi
```

Install [AWS IAM Authenticator for Kubernetes](https://github.com/kubernetes-sigs/aws-iam-authenticator):

```bash
if [ ! -x /usr/local/bin/aws-iam-authenticator ]; then
  sudo curl -s -Lo /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
  sudo chmod a+x /usr/local/bin/aws-iam-authenticator
fi
```

## Configure AWS

Authorize to AWS using AWS CLI: [https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

```bash
aws configure
...
```

Create DNS zone:

```bash
aws route53 create-hosted-zone --name ${MY_DOMAIN} --caller-reference ${MY_DOMAIN}
```

Use your domain registrar to change the nameservers for your zone (for example
`mylabs.dev`) to use the Amazon Route 53 nameservers. Here is the way how you
can find out the the Route 53 nameservers:

```bash
aws route53 get-hosted-zone \
  --id $(aws route53 list-hosted-zones --query "HostedZones[?Name==\`${MY_DOMAIN}.\`].Id" --output text) \
  --query "DelegationSet.NameServers"
```

Create policy allowing the cert-manager to change Route 53 settings. This will
allow cert-manager to generate wildcard SSL certificates by Let's Encrypt
certificate authority.

```bash
aws iam create-policy \
  --policy-name ${USER}-AmazonRoute53Domains-cert-manager \
  --description "Policy required by cert-manager to be able to modify Route 53 when generating wildcard certificates using Lets Encrypt" \
  --policy-document file://files/route_53_change_policy.json
```

Create user which will use the policy above allowing the cert-manager to change
Route 53 settings:

```bash
aws iam create-user --user-name ${USER}-eks-cert-manager-route53
POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName==\`${USER}-AmazonRoute53Domains-cert-manager\`].{ARN:Arn}" --output text)
aws iam attach-user-policy --user-name "${USER}-eks-cert-manager-route53" --policy-arn $POLICY_ARN
aws iam create-access-key --user-name ${USER}-eks-cert-manager-route53 > $HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}
export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" $HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN})
export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" $HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN})
```

The `AccessKeyId` and `SecretAccessKey` is need for creating the `ClusterIssuer`
definition for `cert-manager`.

## Create Amazon EKS

![EKS](https://raw.githubusercontent.com/aws-samples/eks-workshop/65b766c494a5b4f5420b2912d8373c4957163541/static/images/3-service-animated.gif
"EKS")

Generate SSH keys if not exists:

```bash
test -f $HOME/.ssh/id_rsa || ( install -m 0700 -d $HOME/.ssh && ssh-keygen -b 2048 -t rsa -f $HOME/.ssh/id_rsa -q -N "" )
```

Clone the `k8s-harbor` Git repository if it wasn't done already:

```bash
[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor
```

Create [Amazon EKS](https://aws.amazon.com/eks/) in AWS by using [eksctl](https://eksctl.io/).
It's a tool from [Weaveworks](https://weave.works/) based on official
AWS CloudFormation templates which will be used to launch and configure our
EKS cluster and nodes.

![eksctl](https://raw.githubusercontent.com/weaveworks/eksctl/c365149fc1a0b8d357139cbd6cda5aee8841c16c/logo/eksctl.png
"eksctl")

```bash
eksctl create cluster \
--name=${USER}-k8s-harbor \
--tags "Application=Harbor,Owner=${USER},Environment=Test,Division=Services" \
--region=eu-central-1 \
--node-type=t3.medium \
--ssh-access \
--ssh-public-key $HOME/.ssh/id_rsa.pub \
--node-ami=auto \
--node-labels "Application=Harbor,Owner=${USER},Environment=Test,Division=Services" \
--kubeconfig=kubeconfig.conf
```

Output:

```text
[ℹ]  using region eu-central-1
[ℹ]  setting availability zones to [eu-central-1c eu-central-1b eu-central-1a]
[ℹ]  subnets for eu-central-1c - public:192.168.0.0/19 private:192.168.96.0/19
[ℹ]  subnets for eu-central-1b - public:192.168.32.0/19 private:192.168.128.0/19
[ℹ]  subnets for eu-central-1a - public:192.168.64.0/19 private:192.168.160.0/19
[ℹ]  nodegroup "ng-a9d9c670" will use "ami-0d741ed58ca5b342e" [AmazonLinux2/1.12]
[ℹ]  using SSH public key "/home/pruzicka/.ssh/id_rsa.pub" as "eksctl-pruzicka-k8s-harbor-nodegroup-ng-a9d9c670-a3:84:e4:0d:af:5f:c8:40:da:71:68:8a:74:c7:ba:16"
[ℹ]  creating EKS cluster "pruzicka-k8s-harbor" in "eu-central-1" region
[ℹ]  will create 2 separate CloudFormation stacks for cluster itself and the initial nodegroup
[ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=eu-central-1 --name=pruzicka-k8s-harbor'
[ℹ]  2 sequential tasks: { create cluster control plane "pruzicka-k8s-harbor", create nodegroup "ng-a9d9c670" }
[ℹ]  building cluster stack "eksctl-pruzicka-k8s-harbor-cluster"
[ℹ]  deploying stack "eksctl-pruzicka-k8s-harbor-cluster"
[ℹ]  building nodegroup stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-a9d9c670"
[ℹ]  --nodes-min=2 was set automatically for nodegroup ng-a9d9c670
[ℹ]  --nodes-max=2 was set automatically for nodegroup ng-a9d9c670
[ℹ]  deploying stack "eksctl-pruzicka-k8s-harbor-nodegroup-ng-a9d9c670"
[✔]  all EKS cluster resource for "pruzicka-k8s-harbor" had been created
[✔]  saved kubeconfig as "kubeconfig.conf"
[ℹ]  adding role "arn:aws:iam::822044714040:role/eksctl-pruzicka-k8s-harbor-nodegr-NodeInstanceRole-QYPHMTHKAPTN" to auth ConfigMap
[ℹ]  nodegroup "ng-a9d9c670" has 0 node(s)
[ℹ]  waiting for at least 2 node(s) to become ready in "ng-a9d9c670"
[ℹ]  nodegroup "ng-a9d9c670" has 2 node(s)
[ℹ]  node "ip-192-168-11-110.eu-central-1.compute.internal" is ready
[ℹ]  node "ip-192-168-55-129.eu-central-1.compute.internal" is ready
[ℹ]  kubectl command should work with "kubeconfig.conf", try 'kubectl --kubeconfig=kubeconfig.conf get nodes'
[✔]  EKS cluster "pruzicka-k8s-harbor" in "eu-central-1" region is ready
```

![EKS Architecture](https://raw.githubusercontent.com/aws-samples/eks-workshop/3e7da75de884d9efeec8e8ba21161169d3e80da7/static/images/introduction/eks-architecture.svg?sanitize=true
"EKS Architecture")

Create CloudFormation stack with Windows Server 2016, which will serve as
Active Directory to use LDAP connection from Harbor:

```bash
ansible-playbook --connection=local -i "127.0.0.1," files/ansible/aws_windows_server_2016.yml
```

You should be able to access Windows Server using RDP:

```bash
xfreerdp /u:Administrator /p:really_long_secret_windows_password /size:1440x810 -wallpaper /cert-ignore /dynamic-resolution /v:winad01.mylabs.dev &> /dev/null &
```

Windows desktop should appear:

![Windows Server](./xfreerdp_windows_server.png "Windows Server")

Create the PostgreSQL database (RDS):

```bash
ansible-playbook --connection=local -i "127.0.0.1," files/ansible/aws_postgresql_db.yml
```

If you check the AD Users you should see users `aduser{01..06}` distributed into
three groups `adgroup{01.03}` with password `admin`.

Check if the new EKS cluster is available:

```bash
export KUBECONFIG=$PWD/kubeconfig.conf
kubectl get nodes -o wide
```

Output:

```text
NAME                                              STATUS   ROLES    AGE   VERSION   INTERNAL-IP      EXTERNAL-IP    OS-IMAGE         KERNEL-VERSION                CONTAINER-RUNTIME
ip-192-168-11-110.eu-central-1.compute.internal   Ready    <none>   24m   v1.12.7   192.168.11.110   3.122.97.63    Amazon Linux 2   4.14.106-97.85.amzn2.x86_64   docker://18.6.1
ip-192-168-55-129.eu-central-1.compute.internal   Ready    <none>   24m   v1.12.7   192.168.55.129   3.121.202.72   Amazon Linux 2   4.14.106-97.85.amzn2.x86_64   docker://18.6.1
```

![EKS High Level](https://raw.githubusercontent.com/aws-samples/eks-workshop/3e7da75de884d9efeec8e8ba21161169d3e80da7/static/images/introduction/eks-high-level.svg?sanitize=true
"EKS High Level")

Both worker nodes should be accessible via SSH:

```bash
for EXTERNAL_IP in $(kubectl get nodes --output=jsonpath="{.items[*].status.addresses[?(@.type==\"ExternalIP\")].address}"); do
  echo "*** ${EXTERNAL_IP}"
  ssh -q -o StrictHostKeyChecking=no -l ec2-user ${EXTERNAL_IP} uptime
done
```

Output:

```text
*** 3.122.97.63
 05:26:51 up 25 min,  0 users,  load average: 0.00, 0.00, 0.00
*** 3.121.202.72
 05:26:52 up 25 min,  0 users,  load average: 0.00, 0.00, 0.00
 ```

At the end of the output you should see 2 IP addresses which
should be accessible by SSH using your public key `~/.ssh/id_rsa.pub`.
