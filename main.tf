variable aws_region {}
variable aws_profile {}

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#locals {
#  common_tags = "${map(
#    "System"	 , "${var.system}",
#    "Owner"	 , "${var.owner}",
#    "Environment", "${var.environment}",
#    "Deployer"	 , "${var.deployer}"
#  )}"
#}

