#!/usr/bin/env bash

# apt-get update -qq && apt-get install -qq -y curl git > /dev/null
# cd /var/tmp/

# export LETSENCRYPT_ENVIRONMENT="production"  # Use with care - Let's Encrypt will generate real certificates
# export MY_DOMAIN="mylabs.dev"
# ./run-k8s-harbor-part1.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor

sed docs/part-0{1,2,4}/README.md \
  -e '/^## Configure AWS/,/^Create policy allowing the cert-manager to change Route 53 settings./d' \
  -e '/^## Install Harbor using Argo CD/,$d' \
| \
sed -n '/^```bash$/,/^```$/p' \
| \
sed '/^```/d' | sh -x
