resource "aws_s3_bucket" "kops-state-bucket" {
  bucket = "kops-state-${lower(var.common_tags["system"])}-${lower(var.common_tags["environment"])}"
  acl    = "private"

  versioning {
    enabled = true
  }
  tags = "${var.common_tags}"
}