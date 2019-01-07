variable "vpc_cidr" {}
variable "aws_zones" {type = "list"}
variable "vpc_private_subnets" {type = "list"}
variable "vpc_public_subnets" {type = "list"}
variable "common_tags" {type = "map" default = {}}
locals {
  system = "${var.common_tags["system"]}"
  environment = "${var.common_tags["environment"]}"
}
variable "kubernetes_cluster_name" {}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "${local.system}-${local.environment}-VPC"
  cidr = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  azs             = "${var.aws_zones}"
  private_subnets = "${var.vpc_private_subnets}"
  public_subnets  = "${var.vpc_public_subnets}"

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true


  public_subnet_tags = {
    Name = "${local.system}-${local.environment}-public"
    # Tags required by k8s to launch services elb here
    "kubernetes.io/role/elb" = true
  }

  private_subnet_tags = {
    Name = "${local.system}-${local.environment}-private"
    # Tags required by k8s to launch services with internal traffic
    "kubernetes.io/role/internal-elb" = true
  }

  # This is so kops knows that the VPC resources can be used for k8s
  tags = "${merge(var.common_tags,
     map(
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}", "shared"
	   )
	 )}"

  #vpc_tags = {
  #  Name = "${local.system}-${local.environment}-VPC"
  #}
}
