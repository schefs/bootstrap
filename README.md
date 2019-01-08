## bootstraping using terraform ##

**What are we going to boostrap here ?**

1 VPC with 4 subnets (2 public & 2 private in different AZ), with NAT GW for each AZ for redundancy.
k8s spread accross all 3 AZ with 1 master in each zone and 3 compute nodes also one in each zone (all in private subnets).
1 bastion host in your vpc for secure ssh access to the cluster.


**Installation requirements**

- Terraform
- Kubectl
- KOPS


**Lets GO !**

- create an AWS IAM User with Programmatic Access and assign following permissions:

    AmazonEC2FullAccess
    AmazonRoute53FullAccess
    AmazonS3FullAccess
    IAMFullAccess
    AmazonVPCFullAccess

- Setup aws key in a credential file.

*You will need to raise the default EIP limit from 5 to 6 at least


- Setup your variables in terraform.tfvars.

Usage in main.tf:

    provider "aws" {
        region = "${var.region}"
        profile = "${var.aws_profile}"
        shared_credentials_file = "/Users/tf_user/.aws/creds" # <---- used to set custom credentials file path.
    }

*You can use any other way for setting the credentials as recommended by Terraform.

Then you can run the following:

    $ terraform validate
    $ terraform init
    $ terraform plan
    $ terraform apply

Note that executing this will create resources which can cost money (VPC, AWS Elastic IP, for example). Don't forget to run `terraform destroy` when you don't need these resources.


## Outputs

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


For security, all master/worker nodes are in a private subnet and not exposed to the Internet. Also instantiate a bastion host as the sole entry point into the cluster via SSH, and the cluster is configured to enable RBAC as its authorization mode. Its control plane/API requires authentication via client certificate based authentication (will be available automatically with deploy automation in your ~/.kube/config).
You will need to create a ssh key pair to access the bastion host if you want to be able to ssh into the nodes.
generate key-pair for kops. it will be saved by deafult in ~/.ssh and kops will setup the .ssh/id_rsa.pub in all created instances.

    $ssh-keygen



We are going to tells Kops that we want to use a private network topology. Our Kubernetes instances will live in private subnets in each zone.
you can chose any kubernetes networking implementations you desire.
I chose Calico for cluster networking for several reasons.
Since we are using a private topology, we cannot use the default kubenet mode (also we are running in multi AZ). Calico allows to surpass the 50 node limit, which exists as a consequence of the AWS 50 route limit when using the VPC routing table.
Since we deploy kubernetes across multiple AZs for high availability then each AZ will have its own subnet so we need a networking solution that can support that like calico.
Within each VPC subnet Calico doesn’t need an overlay, it will enable a larger scale deployment with great performance.
Compared to other networking solutions calico is considered light with a small memory&cpu footprint on the nodes compared to its rivals which is a great plus for my use case.
Calico provides fine-grained network security policy for individual containers. can be useful for a user specific ingress/egress rules natively implemented in kubernetes manifest and not as a third party resource.


Cross-Subnet mode in Calico
With this mode, IP-in-IP encapsulation is only performed selectively. This provides better performance in AWS multi-AZ deployments, and in general when deploying on networks where pools of nodes with L2 connectivity are connected via a router.

kops can spit out its intentions to terraform .tf file to use for initial deploy, but you should note that if you modify the Terraform files that kops spits out, it will override your changes with the configuration state defined by its own configs in the s3 bucket. In other terms, kops own state is the ultimate source of truth (as far as kops is concerned), and Terraform is a representation of that state for your convenience. Meaning that if you run a `kops edit cluster` and update your cluster without also updating your terraform files you will easily get out of sync so for our specific use case without any automation enforcing you to always update the tf state. you can also create a third party resources (like load balancers for your application services) that only kops can destroy during a clusters teardown without the option built in to modify the tf state currently. I think this feature is not mature enough to use in our use case so I would stick to updating the cluster strait from kops for a strait forward approach for every cluster creation, update or teardown. You will need to add `--target=terraform \ --out=. \kops` to your cluster creation to tell kops to spit out its state to terraform. If you still want to do so you can read about it [here](https://github.com/kubernetes/kops/blob/master/docs/terraform.md).


    $ kops create cluster \
     --cloud=aws \
     --state=s3://$(terraform output kops_s3_state_bucket) \
     --node-count 3 \
     --zones us-east-2a,us-east-2b,us-east-2c \
     --master-zones us-east-2a,us-east-2b,us-east-2c \
     --dns-zone=$(terraform output dns_zone_id) \
     --vpc=$(terraform output vpc_id) \
     --dns private \
     --node-size t2.micro \
     --master-size t2.micro \
     --topology private \
     --networking calico \
     --bastion \
     --ssh-public-key ~/.ssh/id_rsa.pub \
     --cloud-labels $(terraform output common_tags|tr '\n' ','|sed 's/ //g'|sed 's/.$//') \
     $(terraform output dns_zone_name)
     
     
     kops create cluster \
     --cloud=aws \
     --state=s3://aws_s3_bucket.kops-state-bucket.bucket} \
     --node-count 3 \
     --zones us-east-2a,us-east-2b,us-east-2c \
     --master-zones us-east-2a,us-east-2b,us-east-2c \
     --dns-zone=aws_route53_zone.private.zone_id \
     --vpc=module.vpc.vpc_id \
     --dns private \
     --node-size t2.micro \
     --master-size t2.micro \
     --topology private \
     --networking calico \
     --bastion \
     --ssh-public-key ~/.ssh/id_rsa.pub \
     --target=terraform \
     --out=. \
     var.kubernetes_cluster_name


     --cloud-labels $(terraform output common_tags|tr '\n' ','|sed 's/ //g'|sed 's/.$//') \



 #--subnets $(terraform output private_subnets|tr -d '\n') \

    $  kops update cluster --yes schef.dev.k8s
check your aws console for your newly created ELB address so you can SSH into the bastion. from here you can ssh into any node in the private subnets.
    ssh -A admin@<bastion-ELB-address>