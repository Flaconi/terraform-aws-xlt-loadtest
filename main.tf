# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.2.0"

  name = "xlt-${var.name}"
  cidr = var.local_network

  azs             = ["eu-central-1a"]
  private_subnets = [local.private_subnet]
  public_subnets  = [local.public_subnet]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = local.tags
}

# Security Group for the EC2 Agents
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name        = "${var.name}-sg"
  description = "Security group for - xceptance - ec2-to-nlb"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = flatten([
    for cidr in concat([var.local_network], var.allowed_networks) : {
      rule        = "all-all"
      cidr_blocks = cidr
  }])

  number_of_computed_ingress_with_self = 1

  computed_ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
  number_of_computed_egress_with_self = 1
  computed_egress_with_self = [
    {
      rule = "all-all"
    },
  ]
  number_of_computed_egress_with_cidr_blocks = 1
  computed_egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

# XLT
module "xceptance_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.1.1"

  count = var.instance_count
  name  = "xlt-${var.name}-${count.index}"

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.keyname
  monitoring             = true
  vpc_security_group_ids = [module.ec2_sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  user_data = "{\"acPassword\":\"${var.password}\",\"hostData\":\"\"}"

  tags = local.tags
}

# Grafana
module "grafana" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "6.1.1"

  name   = "grafana-${var.name}"
  create = var.grafana_enabled ? true : false

  ami                         = var.grafana_ami
  instance_type               = "m4.xlarge"
  key_name                    = var.keyname
  monitoring                  = true
  vpc_security_group_ids      = [module.ec2_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[0]
  private_ip                  = local.graphite_host
  associate_public_ip_address = false

  user_data = "{\"auth\": [ {\"name\": \"admin\", \"pass\": \"${var.password}\"}]}"

  tags = local.tags
}

# Network Load Balancer
resource "aws_lb" "this" {
  count              = local.nlb_count
  name               = "${var.name}-nlb-${count.index}"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = local.tags
}

# Target Group to point to XLT Instances ( Agent port )
resource "aws_lb_target_group" "this" {
  count                = var.instance_count
  name_prefix          = "xlt"
  port                 = "8500"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"

  tags = local.tags
}

# LB Listeners for Agents
resource "aws_lb_listener" "this" {
  count             = var.instance_count
  load_balancer_arn = aws_lb.this[ceil((count.index + 1) / local.instance_count_per_lb) - 1].arn
  port              = count.index + var.start_port_services
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.this[count.index].arn
    type             = "forward"
  }
}

# Target Group Attachment to instance:agentport
resource "aws_lb_target_group_attachment" "agents" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.this[count.index].arn
  target_id        = module.xceptance_cluster[count.index].private_ip
  port             = 8500
}

### GRAFANA
resource "aws_lb_target_group" "grafana" {
  count                = var.grafana_enabled ? 1 : 0
  name_prefix          = "graf"
  port                 = "443"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"

  tags = local.tags
}

# LB Listeners for Grafana
resource "aws_lb_listener" "grafana" {
  count             = var.grafana_enabled ? 1 : 0
  load_balancer_arn = aws_lb.this[local.nlb_count - 1].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    target_group_arn = concat(aws_lb_target_group.grafana.*.arn, [""])[0]
    type             = "forward"
  }
}
# Target Group Attachment to instance:grafanaport
resource "aws_lb_target_group_attachment" "grafana" {
  count            = var.grafana_enabled ? 1 : 0
  target_group_arn = concat(aws_lb_target_group.grafana.*.arn, [""])[0]
  target_id        = module.grafana.private_ip
  port             = 443
}
