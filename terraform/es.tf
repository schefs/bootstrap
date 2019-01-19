variable "ssh_key_pub_location" {}
variable "es_vm_size" {}


resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "terraform_ec2_key" 
  public_key = "${file("${var.ssh_key_pub_location}")}"
}

module "security_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "2.7.0"

  name        = "es sg"
  description = "Security group for Elastic Search internal traffic only"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "elastic_search" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "${var.es_vm_size}"
  count = 1
  vpc_security_group_ids = ["${module.security_group.this_security_group_id}"]
  associate_public_ip_address = false
  subnet_id = "${module.vpc.private_subnets[0]}"
  key_name = "${aws_key_pair.terraform_ec2_key.key_name}"

  tags = "${merge(var.common_tags,
     map(
    "Name", "elastic-search"
	   )
	 )}"
 user_data = "${file("./files/install_es.sh")}"
  
}