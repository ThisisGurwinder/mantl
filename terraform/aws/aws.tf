variable "datacenter" {default = "aws-us-west-2"}
variable "region" {default = "us-west-2"}
variable "short_name" {default = "mantl-testing"}
variable "source_ami" {default ="ami-d440a6e7"}
variable "ssh_username" {default = "centos"}


provider "aws" {
  region = "${var.region}"
}

# _local is for development only s3 or something else should be used
# https://github.com/hashicorp/terraform/blob/master/state/remote/remote.go#L47
# https://www.terraform.io/docs/state/remote.html
resource "terraform_remote_state" "vpc" {
  backend = "_local"
  config {
    path = "./vpc/terraform.tfstate"
  }
}

# s3 example
#resource  "terraform_remote_state" "vpc" {
# backend = "s3"
#  config {
#    bucket = "mybucketname"
#   key = "name_of_state_file"
#  }
#}

#module "vpc" {
#  source ="./vpc"
#  short_name = "${var.short_name}"
#  region = "${var.region}"
#}

module "ssh-key" {
  source ="./ssh"
  short_name = "${var.short_name}"
}

module "control-nodes" {
  source = "./nodes/control"
  datacenter = "${var.datacenter}"
  ssh_username = "${var.ssh_username}"
  source_ami = "${var.source_ami}"
  short_name = "${var.short_name}"
  ssh_key_pair = "${module.ssh-key.ssh_key_name}"
  vpc_id = "${terraform_remote_state.vpc.output.vpc_id}"
  default_security_group_id = "${terraform_remote_state.vpc.output.default_security_group}"
  vpc_subnet_ids = "${terraform_remote_state.vpc.output.subnet_ids}" 
  availability_zones = "${terraform_remote_state.vpc.output.availability_zones}" 
}

module "edge-nodes" {
 source = "./nodes/edge"
  datacenter = "${var.datacenter}"
  ssh_username = "${var.ssh_username}"
  source_ami = "${var.source_ami}"
  short_name = "${var.short_name}"
  ssh_key_pair = "${module.ssh-key.ssh_key_name}"
  availability_zones = "${terraform_remote_state.vpc.output.availability_zones}"
  vpc_id = "${terraform_remote_state.vpc.output.vpc_id}"
  default_security_group_id = "${terraform_remote_state.vpc.output.default_security_group}"
  vpc_subnet_ids = "${terraform_remote_state.vpc.output.subnet_ids}" 
}

module "worker-nodes" {
  source = "./nodes/worker"
  datacenter = "${var.datacenter}"
  ssh_username = "${var.ssh_username}"
  source_ami = "${var.source_ami}"
  short_name = "${var.short_name}"
  ssh_key_pair = "${module.ssh-key.ssh_key_name}"
  availability_zones = "${terraform_remote_state.vpc.output.availability_zones}"
  vpc_id = "${terraform_remote_state.vpc.output.vpc_id}"
  default_security_group_id = "${terraform_remote_state.vpc.output.default_security_group}"
  vpc_subnet_ids = "${terraform_remote_state.vpc.output.subnet_ids}"  
}

