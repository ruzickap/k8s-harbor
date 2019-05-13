#!/bin/bash -eu

sed -n '/^```bash$/,/^```$/p' docs/part-09/README.md | sed -e '/^```*/d' -e '/^aws*/d' -e '/^eksctl*/d' | sh -x
