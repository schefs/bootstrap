#variable "system" {}
#variable "environment" {}
#variable "vpc_cidr" {}
#variable "aws_zones" {type = "list"}
#variable "vpc_private_subnets" {type = "list"}
#variable "vpc_public_subnets" {type = "list"}
#variable "common_tags" {type = "map" default = {}}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "${var.system}-${var.environment}-Vpc-schf"
  cidr = "${var.vpc_cidr}"

  azs             = "${var.aws_zones}"
  private_subnets = "${var.vpc_private_subnets}"
  public_subnets  = "${var.vpc_public_subnets}"

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "${var.common_tags["system"]}-${var.common_tags["environment"]}-public}"
  }

  private_subnet_tags = {
    Name = "${var.common_tags["system"]-$var.common_tags["environment"]-private}"
  }
#
#  tags = "${merge(
#           var.common_tags,
#	   map(
#	     "wat", "awesome-app-server",
#	     "Role", "server"
#	   )
#	 )}"

  vpc_tags = {
    Name = "${var.system}-${var.environment}-VPC"
  }
}
