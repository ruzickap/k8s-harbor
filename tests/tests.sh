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

echo "*** Configure \"DNS\" /etc/hosts"
DNS_NAMES="harbor notary"
grep -q "172.17.255.1 ${MY_DOMAIN}" /etc/hosts || sudo bash -c "echo '172.17.255.1 ${MY_DOMAIN}' >> /etc/hosts"
for DNS_NAME in $DNS_NAMES; do
  if ! grep -q "172.17.255.1 ${DNS_NAME}.${MY_DOMAIN}" /etc/hosts; then
    echo "*** Adding \"172.17.255.1 ${DNS_NAME}.${MY_DOMAIN}\" to /etc/hosts"
    sudo bash -c "echo '172.17.255.1 ${DNS_NAME}.${MY_DOMAIN}' >> /etc/hosts"
  fi
done

echo -e "\n\n******************************\n*** Main tests\n******************************\n"

set +x
test -f ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh

export TYPE_SPEED=60
export PROMPT_TIMEOUT=0
export NO_WAIT=true
export DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

sed docs/part-{02..09}/README.md \
  -e 's/.*aws route53.*/### &/' \
  -e 's/.*aws elb.*/### &/' \
  -e 's/cert-manager-letsencrypt-aws-route53-certificate.yaml | kubectl apply -f -/cert-manager-selfsigned-certificate.yaml | kubectl apply -f - ###/' \
  -e '/--set database./d' \
  -e 's/--set persistence.enabled=true/--set persistence.enabled=false/' \
  -e '/--set persistence.resourcePolicy./d' \
  -e '/--set persistence.persistentVolumeClaim./d' \
  -e 's/^ldapsearch.*/### &/' \
  -e 's/aduser../admin/' \
  -e '/"update finished"/d' \
  -e 's/^aws cloudformation.*/### &/' \
  -e 's/^eksctl*/### &/' \
  -e 's/^aws iam.*/### &/' \
| \
sed -n '/^```bash$/,/^```$/p' \
| \
sed \
  -e 's/^```bash$/\
pe '"'"'/' \
  -e 's/^```$/'"'"'/' \
> README.sh

source README.sh

sudo sed -i '/172.17.255.1/d' /etc/hosts
