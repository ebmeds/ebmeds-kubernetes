To get it runs for testing the following tools are required:
- [Kube-controller to communication with the Kubernetes cluster](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Minikube to run a single-node Kubernetes cluster in a virtual machine](https://kubernetes.io/docs/tasks/tools/install-minikube/)
  - I personally recommend `KVM` for the Linux user and `HyperKit` for Mac user
  - See: https://github.com/kubernetes/minikube/blob/master/docs/drivers.md#kvm2-driver
  - Also, recommend setting Minikube memory to 8 gigabytes before starting it.
    - Command: `minikube config set memory 8196`
- [Terraform to run the EBMEDS infrastructure as code](https://learn.hashicorp.com/terraform/getting-started/install.html#installing-terraform)
- Require Docker authentication configuration file: `~/.docker/config.json` to pull images from Quay.
  - This should already exist but if it's missing just login to Quay registry.

```bash
# Start Minikube followingly from repo root:
$ minikube start --extra-config=apiserver.service-node-port-range=80-10000

# To spin up ebmeds
$ kubectl apply -f module/elastic/static/elastic.yml
$ terraform apply

# To check api-gateway status
$ curl $(minikube ip):3001/status
```

TODO:
- [x] EBMEDS Kubernetes
   - [x] Services load order
   - [x] Modularisation
- [x] Elastic stack 
- [ ] Ingress
- [ ] Environment support
