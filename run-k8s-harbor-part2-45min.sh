#!/usr/bin/env bash

set -eu

################################################
# include the magic
################################################
test -f ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
# shellcheck disable=SC1091
. ./demo-magic.sh

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
export TYPE_SPEED=60

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=0

# No wait
export NO_WAIT=false

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
export DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# hide the evidence
#clear

sed docs/part-0{6..8}/README.md \
  -e '/^## Upload Helm Chart using CLI/,/^## Upload signed Helm Chart using CLI/d' \
  -e '/^## Signed container image/,/^## Vulnerability scan/d' \
| \
sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p;/^-----$/p" \
| \
sed \
  -e 's/^-----$/\np  ""\np  "################################################################################################### Press <ENTER> to continue"\nwait\n/' \
  -e 's/^```bash.*/\npe '"'"'/' \
  -e 's/^```$/'"'"'/' \
> README.sh


if [ "$#" -eq 0 ]; then
  ### Please run these commands before running the script

  # mkdir /var/tmp/test && cd /var/tmp/test
  # git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor

  export LETSENCRYPT_ENVIRONMENT=${LETSENCRYPT_ENVIRONMENT:-staging}
  # export LETSENCRYPT_ENVIRONMENT="production" # Use with care - Let's Encrypt will generate real certificates
  # ./run-k8s-harbor-part2-45min.sh

  export MY_DOMAIN="mylabs.dev"
  EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID
  EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY
  eksctl utils write-kubeconfig --kubeconfig kubeconfig.conf --name="${USER}-k8s-harbor"
  echo -e "\n${MY_DOMAIN} | ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID} | ${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}\n$(kubectl --kubeconfig=./kubeconfig.conf cluster-info)"

  if [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID}" ] || [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}" ]; then
    echo -e "\n*** One of the mandatory variables 'EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID' or 'EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY' is not set !!\n";
    exit 1
  fi

  cat << \EOF
*** Wait until Clair Vulnerability database will be fully updated
export KUBECONFIG=$PWD/kubeconfig.conf
CLAIR_POD=$(kubectl get pods -l "app=harbor,component=clair" -n harbor-system -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n harbor-system ${CLAIR_POD}
EOF
  export KUBECONFIG=$PWD/kubeconfig.conf
  # CLAIR_POD=$(kubectl get pods -l "app=harbor,component=clair" -n harbor-system -o jsonpath="{.items[0].metadata.name}")
  # COUNT=0
  # while ! kubectl logs -n harbor-system ${CLAIR_POD} | grep "update finished"; do COUNT=$((COUNT+1)); echo -n "${COUNT} "; sleep 10; done

  set -eux
  ansible localhost -m wait_for -a "port=5986 host=winad01.${MY_DOMAIN}"

  kubectl get secrets "ingress-cert-${LETSENCRYPT_ENVIRONMENT}" -n harbor-system

  if [ "${LETSENCRYPT_ENVIRONMENT}" = "staging" ]; then
    sudo mkdir -pv /etc/docker/certs.d/harbor.${MY_DOMAIN}/
    CA_CERT=$(kubectl get secrets ingress-cert-staging -n cert-manager -o jsonpath="{.data.ca\.crt}")
    [ "${CA_CERT}" != "<nil>" ] && echo "${CA_CERT}" | base64 -d > /tmp/ca.crt
    test -s /tmp/ca.crt || wget -q https://letsencrypt.org/certs/fakelerootx1.pem -O /tmp/ca.crt
    sudo cp /tmp/ca.crt /etc/docker/certs.d/harbor.${MY_DOMAIN}/ca.crt
    export SSL_CERT_FILE=/tmp/ca.crt
    for EXTERNAL_IP in $(kubectl get nodes --output=jsonpath="{.items[*].status.addresses[?(@.type==\"ExternalIP\")].address}"); do
      ssh -q -o StrictHostKeyChecking=no -l ec2-user "${EXTERNAL_IP}" \
        "sudo mkdir -p /etc/docker/certs.d/harbor.${MY_DOMAIN}/ && sudo wget -q https://letsencrypt.org/certs/fakelerootx1.pem -O /etc/docker/certs.d/harbor.${MY_DOMAIN}/ca.crt"
    done
    echo "*** Done"
  fi

  # Upload kuard image to harbor.${MY_DOMAIN}/library - necessary for part-08 (Use image hosted by Harbor in k8s deployment)
  echo admin | docker login --username aduser05 --password-stdin harbor.${MY_DOMAIN}
  docker pull gcr.io/kuar-demo/kuard-amd64:blue
  docker tag gcr.io/kuar-demo/kuard-amd64:blue harbor.${MY_DOMAIN}/library/kuard-amd64:blue
  docker push harbor.${MY_DOMAIN}/library/kuard-amd64:blue
  docker rmi harbor.${MY_DOMAIN}/library/kuard-amd64:blue

  # Pull docker image (prefetch)
  docker pull nginx:1.13.12

  cd tmp

  awk "/${MY_DOMAIN}/" /etc/hosts
  set +eux

  echo -e "\n\n*** Press ENTER to start\n"
  read -r

  # hide the evidence
  clear
  # shellcheck disable=SC1091
  source ../README.sh
else
  cat README.sh
fi
