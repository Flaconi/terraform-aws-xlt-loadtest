variable "ami" {
	default="ami-0fc36223101444802"
	type=string
}

variable "allowed_networks" {
	default= ["185.28.184.194/32"]
	type=list(string)
}

variable "instance_count" {
	default= 2
	type=string
}
