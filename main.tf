# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "xlt - ${var.name}"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "xceptance"
  }
}

# Network Load Balancer
module "nlb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name        = "xceptance-sg"
  description = "Security group for - xceptance - nlb"
  vpc_id      = module.vpc.vpc_id

  number_of_computed_ingress_with_cidr_blocks = 1
  computed_ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = var.allowed_networks
  }]
}

# Security Group for the EC2 Agents
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.0.1"

  name        = "xceptance-sg"
  description = "Security group for - xceptance - ec2-to-nlb"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.nlb_sg.this_security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
}

# XLT Cluster
module "xceptance_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "xceptance-sg"
  instance_count = var.instance_count

  ami                    = var.ami
  instance_type          = "c4.xlarge"
  key_name               = ""
  monitoring             = true
  vpc_security_group_ids = [module.ec2_sg.this_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  user_data = "{\"acPassword\":\"${var.password}\",\"hostData\":\"\"}"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


# Network Load Balancer
resource "aws_lb" "this" {
  name               = "xceptance-service-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Terraform = "true"
  }
}
# Target Group to point to XLT Instances ( Agent port )
resource "aws_lb_target_group" "this" {
  count                = var.instance_count
  name_prefix          = "xcept"
  port                 = "8500"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"

  tags = {
    Terraform = "true"
  }
}


# Target Group to point to XLT Instances ( SSH Port)
resource "aws_lb_target_group" "ssh" {
  count                = var.instance_count
  name_prefix          = "xcept"
  port                 = "ssh"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"

  tags = {
    Terraform = "true"
  }
}

# LB Listeners for Agents
resource "aws_lb_listener" "this" {
  count             = var.instance_count
  load_balancer_arn = aws_lb.this.arn
  port              = count.index + var.start_port_services
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.this[count.index].arn}"
    type             = "forward"
  }
}

# LB Listeners for SSH
resource "aws_lb_listener" "ssh" {
  count             = var.instance_count
  load_balancer_arn = aws_lb.this.arn
  port              = count.index + var.ssh_port_services
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.ssh[count.index].arn}"
    type             = "forward"
  }
}

# Target Group Attachment to instance:agentport
resource "aws_lb_target_group_attachment" "agents" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.this[count.index].arn
  target_id        = module.xceptance_cluster.private_ip[count.index]
  port             = 8500
}

# Target Group Attachment to instance:ssh
resource "aws_lb_target_group_attachment" "ssh" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.ssh[count.index].arn
  target_id        = module.xceptance_cluster.private_ip[count.index]
  port             = 22
}
