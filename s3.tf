resource "aws_s3_bucket" "kops-state-bucket" {
  bucket = "kops-state-${lower(var.common_tags["system"])}-${lower(var.common_tags["environment"])}"
  acl = "private"
  force_destroy = true
  # Important if you want to save versions of your k8s cluster configuration.
  versioning {
    enabled = true
  }
  tags = "${merge(var.common_tags)}"
}