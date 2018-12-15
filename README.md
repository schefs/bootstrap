## bootstraping using terraform ##

Setup aws key in a credential file 

Setup your variables in terraform.tfvars

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
