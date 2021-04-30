# Kubernetes + Harbor

[![Build Status](https://github.com/ruzickap/k8s-harbor/workflows/build/badge.svg)](https://github.com/ruzickap/k8s-harbor)

[Harbor](https://goharbor.io/) is an open source cloud native registry that
stores, signs, and scans container images for vulnerabilities.

![Harbor](./harbor-horizontal-color.svg "Harbor")

Harbor solves common challenges by delivering trust, compliance, performance,
and interoperability. It fills a gap for organizations and applications that
cannot use a public or cloud-based registry, or want a consistent experience
across clouds.

* Demo GitHub repository: [https://github.com/ruzickap/k8s-harbor](https://github.com/ruzickap/k8s-harbor)
* Demo Web Pages: [https://ruzickap.github.io/k8s-harbor](https://ruzickap.github.io/k8s-harbor)
* Presentation git repository: [https://github.com/ruzickap/k8s-harbor-presentation](https://github.com/ruzickap/k8s-harbor-presentation)
* Presentation URL: [https://ruzickap.github.io/k8s-harbor-presentation](https://ruzickap.github.io/k8s-harbor-presentation)
* YouTube: [Harbor presentation in Czech language](https://youtu.be/niZJOM7ND24)
* Asciinema screencast: [https://asciinema.org/a/253519](https://asciinema.org/a/253519)
* Asciinema screencast (45 minutes): [https://asciinema.org/a/278803](https://asciinema.org/a/278803)

## Requirements

* [ansible](https://ansible.com)
* [awscli](https://aws.amazon.com/cli/)
* [AWS IAM Authenticator for Kubernetes](https://github.com/kubernetes-sigs/aws-iam-authenticator)
* [AWS account](https://aws.amazon.com/account/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [eksctl](https://eksctl.io/)
* Kubernetes, Docker, Linux, AWS knowledge required

## Objectives

* Download and install Harbor to your Kubernetes cluster

## Lab Architecture

![Lab architecture](https://raw.githubusercontent.com/ruzickap/k8s-harbor-presentation/master/images/harbor_demo_architecture_diagram.svg?sanitize=true
"Lab architecture")

## Content

* [Part 01 - Create EKS cluster](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-01/README.md)
* [Part 02 - Install Helm](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-02/README.md)
* [Part 03 - ingress-nginx + cert-manager installation](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-03/README.md)
* [Part 04 - Harbor installation](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-04/README.md)
* [Part 05 - Initial Harbor tasks](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-05/README.md)
* [Part 06 - Harbor and Helm charts](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-06/README.md)
* [Part 07 - Harbor and container images](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-07/README.md)
* [Part 08 - Project settings](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-08/README.md)
* [Part 09 - Clean-up](https://github.com/ruzickap/k8s-harbor/tree/master/docs/part-09/README.md)

## Links

* Video:

  * [Intro to Harbor](https://youtu.be/Rs3zByxI8aY)
  * [Intro: Harbor - James Zabala & Henry Zhang, VMware](https://youtu.be/RZQVBWwGa2s)
  * [Deep Dive: Harbor - Tan Jiang & Jia Zou, VMware](https://youtu.be/OKj1XxtsTCo)

* Pages:

  * [Deploying Harbor Container Registry in Production](https://medium.com/@ikod/deploy-harbor-container-registry-in-production-89352fb1a114)
  * [How to install and use VMware Harbor private registry with Kubernetes](https://blog.inkubate.io/how-to-use-harbor-private-registry-with-kubernetes/)
  * [Use the Notary client for advanced users](https://docs.docker.com/notary/advanced_usage/)
  * [Signing Docker images with Notary server](https://werner-dijkerman.nl/2019/02/24/signing-docker-images-with-notary-server/)
  * [Handy API Harbor calls (in Chinese)](https://cloud.tencent.com/developer/article/1151425)
  * [Swagger Editor](https://editor.swagger.io/) + Import [Harbor's swagger.yaml](https://raw.githubusercontent.com/goharbor/harbor/7b6e83090e26d171c0d0e0dacd14e2b61fab45e1/API/harbor/swagger.yaml)

![Harbor](https://raw.githubusercontent.com/cncf/artwork/ab42c9591f6e0fdccc62c7b88f353d3fdc825734/harbor/stacked/color/harbor-stacked-color.svg?sanitize=true
"Harbor")
