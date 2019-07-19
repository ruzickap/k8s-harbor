#!/bin/bash -eu

export MY_DOMAIN="mylabs.dev"
export LETSENCRYPT_ENVIRONMENT="staging"
export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID="none"
export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY="none"

test -d files || ( echo -e "\n*** Run in top level directory\n"; exit 1 )

echo "*** Remove cluster (if exists)"
kind get clusters | grep 'k8s-harbor-test' && kind delete cluster --name k8s-harbor-test

echo "*** Create a new Kubernetes cluster using kind"
cat << EOF | kind create cluster --name k8s-harbor-test --config -
kind: Config
apiVersion: kind.sigs.k8s.io/v1alpha2
nodes:
- role: control-plane
  replicas: 1
- role: worker
  replicas: 3
EOF

echo "*** Set KUBECONFIG environment variable"
cp $(kind get kubeconfig-path --name k8s-harbor-test) kubeconfig.conf
export KUBECONFIG=${KUBECONFIG:-$PWD/kubeconfig.conf}

echo "*** Install MetalLB"
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

echo "*** Configure MetalLB"
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.17.255.1-172.17.255.250
EOF

echo "*** Configure \"DNS\" in /etc/hosts and in CoreDNS inside k8s"
DNS_NAMES="${MY_DOMAIN} harbor.${MY_DOMAIN} notary.${MY_DOMAIN}"

grep -q "172.17.255.1 ${DNS_NAMES}" /etc/hosts || sudo bash -c "echo '172.17.255.1 ${DNS_NAMES}' >> /etc/hosts"
kubectl get -n kube-system cm/coredns -o yaml | sed "/kubernetes cluster.local in-addr.arpa ip6.arpa/i \ \ \ \ \ \ \ \ hosts ${MY_DOMAIN}.hosts ${MY_DOMAIN} { \n          172.17.255.1 ${DNS_NAMES}\n          fallthrough\n        }" | kubectl apply -f -
kubectl get pods -l k8s-app=kube-dns -n kube-system -o name | xargs kubectl delete -n kube-system

echo -e "\n\n******************************\n*** Main tests\n******************************\n"

test -s ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh

export TYPE_SPEED=60
export PROMPT_TIMEOUT=0
export NO_WAIT=true
export DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

sed docs/part-{02..09}/README.md \
  -e 's/.*aws route53.*/### &/' \
  -e 's/.*aws elb.*/### &/' \
  -e 's/cert-manager-letsencrypt-aws-route53-certificate.yaml | kubectl apply -f -/cert-manager-selfsigned-certificate.yaml | kubectl apply -f - ###/' \
  -e 's/^ldapsearch.*/### &/' \
  -e 's/aduser../admin/' \
  -e '/"update finished"/d' \
  -e 's/^aws cloudformation.*/### &/' \
  -e 's/^eksctl*/### &/' \
  -e 's/^aws iam.*/### &/' \
| \
sed -n '/^```bash.*/,/^```$/p' \
| \
sed \
  -e 's/^```bash.*/\
pe '"'"'/' \
  -e 's/^```$/'"'"'/' \
> README.sh

source README.sh

sudo sed -i '/172.17.255.1/d' /etc/hosts
