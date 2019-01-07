# VPC
output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${module.vpc.vpc_id}"
}

# CIDR blocks
output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = ["${module.vpc.vpc_cidr_block}"]
}


# Subnets
output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${module.vpc.private_subnets}"]
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${module.vpc.public_subnets}"]
}

# NAT gateways
output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = ["${module.vpc.nat_public_ips}"]
}

# KOPS s3 state bucket
output "kops_s3_state_bucket" {
  description = "Name of the bucket that stores kops cluster state"
  value       = ["${aws_s3_bucket.kops-state-bucket.bucket}"]
}
 
 output "dns_zone_id" {
   description = "ID of the route53 dns zone"
   value =  "${aws_route53_zone.private.zone_id}"
 }
  output "dns_zone_name" {
   description = "Name of the route53 dns zone"
   value =  "${var.kubernetes_cluster_name}"
 }
 output "common_tags" {
   description = "common tags used across all aws resources"
   value = "${var.common_tags}"
 }