To get it running for testing the following tools are required:
- [Kube-controller to communication with the Kubernetes cluster](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Minikube to run a single-node Kubernetes cluster in a virtual machine](https://kubernetes.io/docs/tasks/tools/install-minikube/)
  - We recommend `KVM` for the Linux user and `HyperKit` for Mac user
  - See: https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver
  - Also, recommended setting Minikube memory to 8 gigabytes before starting it.
    - Command: `minikube config set memory 8196`
- [Terraform to run the EBMEDS infrastructure as code](https://learn.hashicorp.com/terraform/getting-started/install.html#installing-terraform)
- Require Docker authentication configuration file: `~/.docker/config.json` to pull EBMEDS images from Quay.
  - This should already exist but if it's missing just login to Quay registry.

```bash
# Start Minikube followingly from repo root:
$ minikube start --extra-config=apiserver.service-node-port-range=80-10000

# To spin up ebmeds
$ terraform apply
$ kubectl apply -f module/elastic/static/elastic.yml

# To check api-gateway status
$ curl $(minikube ip):3001/status
```

This repository is meant to provide a bare minimum deployment example of EBMEDS on Kubernetes. Integrators should adapt these instructions to their environments and specific needs. Container architecture should not be changed. Other modifications can be done as needed. Things to consider when deploying EBMEDS on Kubernetes:

- Use an ingress to suit your needs
- Load-balancing highly recommended
    - A single EBMEDS instance should not receive more than 5 RPS
- Auto-scaling highly recommended
- Play around with Kubernetes liveness-probes to avoid unnecessary killing of containers in case of high load
    - *periodSeconds* and *failureThreshold*

For further information and instructions on installing EBMEDS, please visit our online documentation at: https://ebmeds.github.io/docs/
The online documentation site is currently under construction.