# Kubernetes + Harbor

[![Build Status](https://travis-ci.com/ruzickap/k8s-harbor.svg?branch=master)](https://travis-ci.com/ruzickap/k8s-harbor)

[Harbor](https://goharbor.io/) is an open source cloud native registry that
stores, signs, and scans container images for vulnerabilities.

![Harbor](./.vuepress/public/harbor-horizontal-color.svg "Harbor")

Harbor solves common challenges by delivering trust, compliance, performance,
and interoperability. It fills a gap for organizations and applications that
cannot use a public or cloud-based registry, or want a consistent experience
across clouds.

* GitHub repository: [https://github.com/ruzickap/k8s-harbor](https://github.com/ruzickap/k8s-harbor)
* Web Pages: [https://ruzickap.github.io/k8s-harbor](https://ruzickap.github.io/k8s-harbor)

## Requirements

* [awscli](https://aws.amazon.com/cli/)
* [AWS IAM Authenticator for Kubernetes](https://github.com/kubernetes-sigs/aws-iam-authenticator)
* [AWS account](https://aws.amazon.com/account/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [eksctl](https://eksctl.io/)
* Kubernetes and Linux knowledge required

## Objectives

* Download and install Harbor to your cluster

## Content

* [Part 01 - Create EKS cluster](part-01/README.md)
* [Part 02 - Install Helm](part-02/README.md)
* [Part 03 - Nginx + cert-manager installation](part-03/README.md)
* [Part 04 - Harbor installation](part-04/README.md)

## Links

* Video:

  * [Intro to Harbor](https://youtu.be/Rs3zByxI8aY)

* Pages:

  * [Deploying Harbor Container Registry in Production](https://medium.com/@ikod/deploy-harbor-container-registry-in-production-89352fb1a114)

![Harbor](https://raw.githubusercontent.com/cncf/artwork/ab42c9591f6e0fdccc62c7b88f353d3fdc825734/harbor/stacked/color/harbor-stacked-color.svg?sanitize=true)
