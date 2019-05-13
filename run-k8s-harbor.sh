#!/usr/bin/env bash

################################################
# include the magic
################################################
test -f ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
. ./demo-magic.sh -n

################################################
# Configure the options
################################################

#
# speed at which to simulate typing. bigger num = faster
#
TYPE_SPEED=60

# Uncomment to run non-interactively
export PROMPT_TIMEOUT=${PROMPT_TIMEOUT:-0}

# No wait
export NO_WAIT=${NO_WAIT:-false}

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_PROMPT="${GREEN}➜ ${CYAN}$ "

# hide the evidence
clear

### Please run these commands before running the script

# mkdir /var/tmp/test && cd /var/tmp/test
# git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor

# export LETSENCRYPT_ENVIRONMENT="production" # Use with care - Let's Encrypt will generate real certificates
# export MY_DOMAIN="mylabs.dev"


# export EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID=$(awk -F\" "/AccessKeyId/ { print \$4 }" $HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN})
# export EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY=$(awk -F\" "/SecretAccessKey/ { print \$4 }" $HOME/.aws/${USER}-eks-cert-manager-route53-${MY_DOMAIN})
# eksctl utils write-kubeconfig --kubeconfig kubeconfig.conf --name=${USER}-k8s-harbor
# echo -e "\n${LETSENCRYPT_ENVIRONMENT} | ${MY_DOMAIN} | ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID} | ${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY}\n`kubectl --kubeconfig=./kubeconfig.conf cluster-info`"

# export NO_WAIT=true
# ./run-k8s-harbor.sh

if [ -z ${EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID+x} ] || [ -z ${EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY+x} ]; then
  echo "One of the mandatory variables 'EKS_CERT_MANAGER_ROUTE53_AWS_ACCESS_KEY_ID' or 'EKS_CERT_MANAGER_ROUTE53_AWS_SECRET_ACCESS_KEY' is not set !!";
  exit 1
fi

sed '/^## Prepare the local working environment/,/^You should be able to access Windows Server using RDP/d' docs/part-{01..08}/README.md | \
sed -n '/^```bash$/,/^```$/p;/^-----$/p'  | \
sed -e 's/^-----$/\
p  ""\
p  "################################################################################################### Press <ENTER> to continue"\
wait\
/' \
-e 's/^```bash$/\
pe '"'"'/' \
-e 's/^```$/'"'"'/' \
-e '/^sleep/d' \
> README.sh

source README.sh
