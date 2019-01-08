resource "aws_route53_zone" "private" {
  name = "${var.kubernetes_cluster_name}"

  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }
}