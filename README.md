# Bootstrapping

**What are we going to bootstrap here ?**

1 VPC with 6 subnets (3 public & 3 private in different AZ), with NAT GW for each AZ for redundancy for vm workload.

Another 6 subnets for k8s (3 private for compute nodes and 3 infra for masters API, LB, bastion host etc..)

k8s spread across all 3 AZ with 1 master in each zone and 3 compute nodes spread across the region (all in private subnets).

1 bastion host in your vpc for secure ssh access to the environment.

*All k8s nodes including the master and bastion host will be created in a auto scaling group for dealing with recovery scenarios in case of servers fault.

We`ll use route 53 internal hosted dns zone without a real domain.
If you want to use a real domain, that will work out great for you also, especially with k8s ingress sub-domain HOST proxy redirect will help you to save money on LoadBalancer and expose internal services with ease.

We are going to run a dummy-exporter, Nginx ingress controller, k8s-dashboard, Heapster, Kube-state-metrics, node exporters, Prometheus-operator, Grafana, alert manager cluster, fluentd daemonset, kibana and elastic search (on vm).

## Installation requirements

- Terraform
- Kubectl
- KOPS

## Lets start with terraform

- create an AWS IAM User with Programmatic Access and assign following permissions:

      AmazonEC2FullAccess
      AmazonRoute53FullAccess
      AmazonS3FullAccess
      IAMFullAccess
      AmazonVPCFullAccess

- Setup aws key in a credential file.

*You will need to raise the default aws account EIP limit from 5 to 7 at least

- Setup your variables in terraform.tfvars.

Usage in main.tf:

    provider "aws" {
        region = "${var.region}"
        profile = "${var.aws_profile}"
        shared_credentials_file = "/Users/tf_user/.aws/creds" # <---- used to set custom credentials file path.
    }

*You can use any other way for setting the credentials as recommended by Terraform.

## SSH

For security, all master/worker nodes are in a private subnet and not exposed to the Internet, as well as other vms in the project. we'll instantiate a bastion host as the sole entry point into the environment via SSH. k8s cluster is configured to enable RBAC as its authorization mode. Its control plane/API requires authentication via client certificate based authentication (will be available automatically with deploy automation in your ~/.kube/config).
You will need to create a ssh key pair to access the bastion host if you want to be able to ssh into the nodes.
generate key-pair for kops and terraform. it will be saved by deafult in ~/.ssh and kops will setup the .ssh/id_rsa.pub in all created instances.

    $ssh-keygen

if you plan to use a different key for terraform make sure you update terraform.tfvars file with the location of that key.

Then you can run the following:

    $ cd ./terraform
    $ terraform validate
    $ terraform init
    $ terraform plan
    $ terraform apply

Note that executing this will create resources which can cost money (VPC, AWS Elastic IP, for example). Don't forget to run `terraform destroy` when you don't need these resources.

### Outputs

| Name | Description |
|------|-------------|
| nat\_public\_ips | List of public Elastic IPs created for AWS NAT Gateway |
| private\_subnets | List of IDs of private subnets |
| public\_subnets | List of IDs of public subnets |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_id | The ID of the VPC |
| kops\_s3\_state\_bucket| Name of the bucket that stores kops cluster state |
| dns\_zone\_id | ID of the route53 dns zone |
| dns\_zone\_name | Name of the route53 dns zone |
| common\_tags | Map of common tags used across all aws resources |
| AZ | List of AZs |
| es_address | Elastic Search nodes ip address |
| es_dns | Elastic Search internal DNS address |
| es_id | Elastic Search instance ID |

## Kubernetes

### Lets talk about networking

We are going to tells Kops that we want to use a private network topology. Our Kubernetes instances will live in private subnets in each zone.
you can chose any kubernetes networking implementations you desire.
I chose Calico for cluster networking for several reasons.

- Since we are using a private topology, we cannot use the default kubenet mode (also we are running in multi AZ).
- Calico allows to surpass the 50 node limit, which exists as a consequence of the AWS 50 route limit when using the VPC routing table.
- Since we deploy kubernetes across multiple AZs for high availability then each AZ will have its own subnet so we need a networking solution that can support that like calico.
- Cross-Subnet mode in Calico. By default, Calico’s IPIP encapsulation applies to all container-to-container traffic. However, encapsulation is only required for container traffic that crosses a VPC subnet boundary. For better performance, you can configure Calico to perform IPIP encapsulation only across VPC subnet boundaries. With this mode, IP-in-IP encapsulation is only performed selectively. This provides better performance in AWS multi-AZ deployments, and in general when deploying on networks where pools of nodes with L2 connectivity are connected via a router.
- BGP route reflectors - Calico by default, routes between nodes within a subnet are distributed using a full node-to-node BGP mesh. Each node automatically sets up a BGP peering with every other node within the same L2 network. This full node-to-node mesh per L2 network has its scaling challenges for larger scale deployments. BGP route reflectors can be used as a replacement to a full mesh, and is useful for scaling up a cluster. Performance benefits are mostly relevant to large ~50-100+ nodes clusters, so if you are planning to go this direction you should Read more here: [BGP route reflectors](https://docs.projectcalico.org/v3.4/usage/routereflector) (The setup of BGP route reflectors is currently out of the scope of kops and needs to be implemented manually).
- Compared to other networking solutions calico is considered light with a small memory&cpu footprint on the nodes compared to its rivals which is a great plus for my use case.
- Calico provides fine-grained network security policy for individual containers. can be useful for a user specific ingress/egress rules natively implemented in kubernetes manifest and not as a third party resource.

### Terraform for KOPS

kops can spit out its intentions to terraform .tf file to use for initial deploy, but you should note that if you modify the Terraform files that kops spits out, it will override your changes with the configuration state defined by its own configs in the s3 bucket.

In other terms, kops own state is the ultimate source of truth (as far as kops is concerned), and Terraform is a representation of that state for your convenience. Meaning that if you run a `kops edit cluster` and update your cluster without also updating your terraform files you will easily get out of sync, so for our specific use case without any automation, you are enforced to always update the tf state manually.

You can also create a third party resources (like load balancers for your application services) that only kops can destroy during a clusters teardown without the option built in to modify the tf state currently.

For those reasons I think this feature is not mature enough to use in our use case so I would stick to updating the cluster using from kops for a strait forward approach for every cluster creation, update or teardown. To use this feature you will need to add `--target=terraform \ --out=. \kops` to your cluster creation to tell kops to spit out its state to terraform. If you still want to do so you can read about it [here](https://github.com/kubernetes/kops/blob/master/docs/terraform.md).

### Spin up a cluster

To initiate cluster state to s3 bucket

    $ deploy-kops.sh

if you are pleased with the output of the resources going to be created you can then run `kops update cluster --yes` to actually create those resources.

### Add Calico Cross-Subnet mode

To enable this mode in a cluster, with Calico as the CNI and Network Policy provider, you must edit the cluster after the previous creation. This will help you to boost networking performance in a larger scale cluster, but its defiantly not obligatory.

`kops edit cluster`  will show you a block like this:

    networking:
      calico: {}

You will need to change that block, and add an additional field, to look like this:

    networking:
      calico:
        crossSubnet: true

Then you will need to run:

    $ kops update cluster --yes

### Accessing the cluster

Your local kubectl install is now configured with you new cluster. run `kubectl get nodes` to make sure everything is up and running.

Check your aws console for your newly created ELB address so you can SSH into the bastion. from here you can ssh into any node in the private subnets (you are probably dont need to do that anyway).

    $ eval "$(ssh-agent)"
    $ ssh-add ~/.ssh/id_rsa
    $ ssh -A -i ~/.ssh/id_rsa admin@<bastion-ELB-address\>

From this host you can ssh to any host you desire in you vpc

    $ ssh admin@10.0.0.1  # for k8s hosts use admin user
    $ ssh ubuntu@10.0.0.2 # for ubuntu vms use ubuntu user

### Deploy manifests to the cluster

    $ cd ../manifests
    $ ./deploy-k8s-resources.sh

### Accessing backed services

Common used resources are accessible through ingress/LB/API proxy.

To get their address run `./describe-fe.sh`

You can proxy to other Back-end services through the k8s api server for secure access when needed.
they will be available in "http://localhost:<service-port\>"

    $ kubectl port-forward -n monitoring service/prometheus-k8s 9090
    $ kubectl port-forward -n monitoring service/alertmanager-main 9093

Note: Grafana user and password is admin:admin by default

### Accessing the kubernetes dashboard

The login credentials are:

First for the authentication with the api server itself you will need to use (this should be used on all api authentication like in Kibana):

- Username: admin
- Password: `$ kops get secrets kube --type secret -oplaintext`

Then after you already see the dashboards ui requesting the token:

- Username: admin
- Password: `$ kops get secrets --type secret admin -oplaintext`

this is done with security in mind preventing admin privileges strait of from authentication stage to the api server and not the dashboard itself.

## Teardown

    $ kops delete cluster --yes
    $ terraform destroy