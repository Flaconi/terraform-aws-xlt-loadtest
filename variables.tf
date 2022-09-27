variable "start_port_services" {
  description = "The first agent of many will be exposed at port 5000 of the NLB, the second on 5001 etc.etc."
  default     = 5000
  type        = number
}
variable "start_port_ssh" {
  description = "The first ssh of the agents will be exposed at port 6000 of the NLB, the second on 6001 etc.etc."
  default     = 6000
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
  default     = ""
  type        = string
}

variable "instance_type" {
  description = "The default instance_type"
  default     = "c5.2xlarge"
  type        = string
}

variable "ami" {
  description = "The AMI used for the agents"
  default     = "ami-0b701f8f19be222c6" # list of recent XLT AMIs https://github.com/Xceptance/XLT/releases
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
