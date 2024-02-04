#!/usr/bin/env bash

set -eu

################################################
# include the magic
################################################
test -s ./demo-magic.sh || curl --silent https://raw.githubusercontent.com/paxtonhare/demo-magic/master/demo-magic.sh > demo-magic.sh
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
clear

### Please run these commands before running the script

# if [ -n "$SSH_AUTH_SOCK" ]; then
#  docker run -it --rm -e USER="$USER" -e SSH_AUTH_SOCK=$SSH_AUTH_SOCK -v $SSH_AUTH_SOCK:$SSH_AUTH_SOCK -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $PWD:/mnt -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.aws:/root/.aws ubuntu
# else
#  docker run -it --rm -e USER="$USER" -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $PWD:/mnt -v $HOME/.ssh:/root/.ssh:ro -v $HOME/.aws:/root/.aws ubuntu
# fi
# echo $(hostname -I) $(hostname) >> /etc/hosts
# apt-get update -qq && apt-get install -qq -y curl git pv > /dev/null
# cd /mnt

# export LETSENCRYPT_ENVIRONMENT="production"  # Use with care - Let's Encrypt will generate real certificates
# export MY_DOMAIN="mylabs.dev"

# ./run-k8s-harbor-full.sh

[ ! -d .git ] && git clone --quiet https://github.com/ruzickap/k8s-harbor && cd k8s-harbor

sed docs/part-{01..08}/README.md \
  -e '/^## Configure AWS/,/^Create policy allowing the cert-manager to change Route 53 settings./d' |
  sed -n "/^\`\`\`bash.*/,/^\`\`\`$/p;/^-----$/p" |
  sed \
    -e 's/^-----$/\np  ""\np  "################################################################################################### Press <ENTER> to continue"\nwait\n/' \
    -e 's/^```bash.*/\npe '"'"'/' \
    -e 's/^```$/'"'"'/' \
    > README.sh

if [ "$#" -eq 0 ]; then
  # shellcheck disable=SC1091
  source README.sh
else
  cat README.sh
fi
