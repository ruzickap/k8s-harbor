#!/bin/bash -eu

sed -n '/^```bash$/,/^```$/p' docs/part-09/README.md \
| \
sed -r \
  -e '/^```*/d' \
  -e '/^aws/d' \
  -e '/^eksctl/d' \
  -e '/harbor2/d' \
  -e '/^helm reset/d' \
  -e '/^kubectl delete (serviceaccount|clusterrolebinding)/d' \
| sh -x
