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

sed docs/part-{01,{04..08}}/README.md \
  -e '/^## Prepare the local working environment/,/^You should be able to access Windows Server using RDP/d' |
  sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p;/^-----$/p" |
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
  # ./run-k8s-harbor-part2.sh

  export MY_DOMAIN="mylabs.dev"
  EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID
  EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" "$HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN}")
  export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY
  eksctl utils write-kubeconfig --kubeconfig kubeconfig.conf --name="${USER}-k8s-harbor"
  echo -e "\n${MY_DOMAIN} | ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID} | ${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}\n$(kubectl --kubeconfig=./kubeconfig.conf cluster-info)"

  if [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID}" ] || [ -z "${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}" ]; then
    echo -e "\n*** One of the mandatory variables 'EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID' or 'EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY' is not set !!\n"
    exit 1
  fi

  cat << \EOF
*** Wait until Clair Vulnerability database will be fully updated
export KUBECONFIG=$PWD/kubeconfig.conf
CLAIR_POD=$(kubectl get pods -l "app=harbor,component=clair" -n harbor-system -o jsonpath="{.items[0].metadata.name}")
kubectl logs -n harbor-system ${CLAIR_POD}
EOF
  export KUBECONFIG=$PWD/kubeconfig.conf
  CLAIR_POD=$(kubectl get pods -l "app=harbor,component=clair" -n harbor-system -o jsonpath="{.items[0].metadata.name}")
  COUNT=0
  while ! kubectl logs -n harbor-system "${CLAIR_POD}" | grep "update finished"; do
    COUNT=$((COUNT + 1))
    echo -n "${COUNT} "
    sleep 10
  done

  set -eux
  ansible localhost -m wait_for -a "port=5986 host=winad01.${MY_DOMAIN}"

  kubectl get secrets "ingress-cert-${LETSENCRYPT_ENVIRONMENT}" -n harbor-system

  awk "/${MY_DOMAIN}/" /etc/hosts
  set +eux

  echo -e "\n\n*** Press ENTER to start\n"
  read -r

  # hide the evidence
  clear
  # shellcheck disable=SC1091
  source README.sh
else
  cat README.sh
fi
