aws_profile	     = "terraform"
common_tags {
  system 	     = "Testing"
  owner              = "Schef"
  environment        = "Dev"
  deployer	     = "Terraform"
}
aws_region	     = "us-east-2"
aws_zones   	     = ["us-east-2a", "us-east-2b"]
vpc_cidr    	     = "10.0.0.0/16"
vpc_private_subnets  = ["10.0.1.0/16", "10.0.2.0/16"]
vpc_public_subnets   = ["10.0.101.0/16", "10.0.102.0/16"]
