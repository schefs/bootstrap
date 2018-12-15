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
    $ 

