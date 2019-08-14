variable "start_port_services" {
  default = "5000"
  type    = number
}
variable "start_port_ssh" {
  default = "6000"
  type    = number
}

variable "local_network" {
  default = "10.0.0.0/16"
  type    = string
}

variable "name" {
  default = "thename"
  type    = string
}

variable "keyname" {
  default = "maarten"
  type    = string
}

variable "instance_type" {
  default = "c4.2xlarge"
  type    = string
}

variable "ami" {
  default = "ami-0f74bf64551726b45"
  type    = string
}

variable "allowed_networks" {
  default = "185.28.184.194/32"
  type    = string
}

variable "instance_count" {
  default = 2
  type    = string
}

variable "password" {
  default = "lalala"
  type    = string
}

variable "grafana_ami" {
  default = "ami-0fc36223101444802"
  type    = string
}
