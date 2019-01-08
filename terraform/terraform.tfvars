aws_profile	     = "terraform"
common_tags {
  system 	        = "Testing"
  owner           = "Schef"
  environment     = "Dev"
  deployer	      = "schef"
  Terraform       = "true"
}
aws_region	     = "us-east-2"
aws_zones   	     = ["us-east-2a", "us-east-2b", "us-east-2c"]
vpc_cidr    	     = "10.0.0.0/16"
vpc_private_subnets  = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]
vpc_public_subnets   = ["10.0.150.0/24", "10.0.151.0/24", "10.0.152.0/24"]
kubernetes_cluster_name = "schef.dev.k8s"
