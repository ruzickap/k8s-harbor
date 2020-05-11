#!/usr/bin/env bash

# apt-get update -qq && apt-get install -qq -y curl git > /dev/null
# cd /var/tmp/

# export LETSENCRYPT_ENVIRONMENT="production"  # Use with care - Let's Encrypt will generate real certificates
# ./run-k8s-harbor-part1-45min.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor || return

grep mylabs.dev /etc/hosts

sed docs/part-0{1..5}/README.md \
  -e '/^## Configure AWS/,/^Create policy allowing the cert-manager to change Route 53 settings./d' \
| \
sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p" \
| \
sed "/^\`\`\`*/d" \
> README.sh

if [ "$#" -eq 0 ]; then
  # shellcheck disable=SC1091
  source README.sh
else
  cat README.sh
fi
