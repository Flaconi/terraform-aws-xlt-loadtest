variable "create_cluster" {
  description = "Controlls if the load test cluster should be created"
  default     = true
  type        = bool
}

variable "create_report_bucket" {
  description = "Controlls if the load test report storage bucket should be created"
  default     = true
  type        = bool
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

variable "master_controller_ami" {
  description = "The AMI used for the master controller"
  default     = "ami-00544f9ad8d9a0458" # Amazon Linux 2023 AMI 2023.8.20250915.0 arm64 HVM kernel-6.1
  type        = string
}

variable "master_controller_instance_type" {
  description = "The instance_type used for the master controller"
  default     = "c8g.2xlarge" # arm64
  type        = string
}

variable "agent_ami" {
  description = "The AMI used for the agents"
  default     = "ami-0db8929bf1d58c81a" # Xceptance-XLT-9.1.2-Debian-12-64bit-arm64 list of recent XLT AMIs https://github.com/Xceptance/XLT/releases
  type        = string
}

variable "agent_instance_type" {
  description = "The instance_type used for the agents"
  default     = "c8g.2xlarge" # arm64
  type        = string
}

variable "agent_count" {
  description = "The amount of instances to start"
  default     = 2
  type        = string
}

variable "password" {
  description = "The password to use"
  type        = string
}

variable "ssh_allowed_cidr_blocks" {
  description = "The cidr blocks alloed ssh"
  default     = ["0.0.0.0/0"]
  type        = list(string)
}

variable "github_token" {
  description = "The Github fine-grained token to checkout the tests"
  default     = ""
  type        = string
}

variable "branch_name" {
  description = "The branch name to checkout the tests"
  default     = "master"
  type        = string
}

variable "tags" {
  description = "The tags to add"
  default     = {}
  type        = map(string)
}
