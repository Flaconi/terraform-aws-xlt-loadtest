variable "start_port_services" {
  description = "The first agent of many will be exposed at port 5000 of the NLB, the second on 5001 etc.etc."
  default     = 5000
  type        = number
}

variable "local_network" {
  description = "The vpc network"
  default     = "10.0.0.0/16"
  type        = string
}

variable "name" {
  description = "The name used for further interpolation"
  type        = string
}

variable "keyname" {
  description = "The existing keyname of the keypair used for connecting with ssh to the agents"
  default     = null
  type        = string
}

variable "instance_type" {
  description = "The default instance_type"
  default     = "c8g.2xlarge" # arm64
  type        = string
}

variable "ami" {
  description = "The AMI used for the agents"
  default     = "ami-0db8929bf1d58c81a" # Xceptance-XLT-9.1.2-Debian-12-64bit-arm64 list of recent XLT AMIs https://github.com/Xceptance/XLT/releases
  type        = string
}

variable "allowed_networks" {
  description = "The allowed networks IP/32"
  type        = list(string)
}

variable "instance_count" {
  description = "The amount of instances to start"
  default     = 2
  type        = string
}

variable "instance_count_per_lb" {
  description = "The amount of instances per lb"
  default     = 50
  type        = string
}

variable "password" {
  description = "The password to use"
  type        = string
}

variable "grafana_enabled" {
  description = "Do we create a custom Grafana instance"
  default     = false
  type        = bool
}


variable "grafana_ami" {
  description = "The grafana ami (required if grafana_enabled is set to true)"
  default     = "ami-0fc36223101444802"
  type        = string
}

variable "tags" {
  description = "The tags to add"
  default     = {}
  type        = map(string)
}

variable "master_controller_create" {
  description = "Whether to create an XLT Master Controller instance"
  default     = false
  type        = bool
}

variable "master_controller_ami" {
  description = "The AMI used for the master controller"
  default     = "ami-0b7c9879f1e078eb1" # Amazon Linux 2023 AMI 2023.8.20250915.0 arm64 HVM kernel-6.1
  type        = string
}

variable "master_controller_instance_type" {
  description = "The instance_type used for the master controller"
  default     = "c8g.2xlarge" # arm64
  type        = string
}

variable "master_controller_ssh_port" {
  description = "The port on the nlb to forward to the master controller's ssh"
  default     = 6022
  type        = number
}

variable "master_controller_github_token" {
  description = "The Github fine-grained token to checkout the tests"
  default     = ""
  type        = string
}

variable "master_controller_xlt_tests_branch" {
  description = "The branch name to checkout the tests"
  default     = "master"
  type        = string
}
