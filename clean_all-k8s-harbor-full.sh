#!/bin/bash -eu

sed -n '/^```bash$/,/^```$/p' docs/part-09/README.md | sed '/^```*/d' | sh -x
