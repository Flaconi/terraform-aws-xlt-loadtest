locals {
  private_subnet = cidrsubnet(var.local_network, 8, 1)
  public_subnet  = cidrsubnet(var.local_network, 8, 101)
  graphite_host  = cidrhost(local.private_subnet, 200)

  tags = merge(
    var.tags,
    {
      "Name"        = "${var.name}"
      "Environment" = "xlt"
    },
  )
}


# VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "xlt - ${var.name}"
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
  version = "3.0.1"

  name        = "${var.name} - sg"
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
      rule        = "all-all"
      cidr_blocks = "0.0.0.0/0"
  }, ]
}

# XLT
module "xceptance_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "xlt-${var.name}"
  instance_count = var.instance_count

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.keyname
  monitoring             = true
  vpc_security_group_ids = [module.ec2_sg.this_security_group_id]
  subnet_id              = module.vpc.private_subnets[0]

  user_data = "{\"acPassword\":\"${var.password}\",\"hostData\":\"\"}"

  tags = local.tags
}

# Grafana
module "grafana" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  name           = "grafana-${var.name}"
  instance_count = var.grafana_enabled ? 1 : 0

  ami                         = var.grafana_ami
  instance_type               = "m4.xlarge"
  key_name                    = var.keyname
  monitoring                  = true
  vpc_security_group_ids      = [module.ec2_sg.this_security_group_id]
  subnet_id                   = module.vpc.private_subnets[0]
  private_ip                  = local.graphite_host
  associate_public_ip_address = false

  user_data = "{\"auth\": [ {\"name\": \"admin\", \"pass\": \"${var.password}\"}]}"

  tags = local.tags
}

# Network Load Balancer
resource "aws_lb" "this" {
  name               = "${var.name}-nlb"
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


# Target Group to point to XLT Instances ( SSH Port)
resource "aws_lb_target_group" "ssh" {
  count                = var.instance_count
  name_prefix          = "xltssh"
  port                 = "22"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"

  tags = local.tags
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
  port              = count.index + var.start_port_ssh
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
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    target_group_arn = concat(aws_lb_target_group.grafana.*.arn, [""])[0]
    type             = "forward"
  }
}
# Target Group Attachment to instance:ssh
resource "aws_lb_target_group_attachment" "grafana" {
  count            = var.grafana_enabled ? 1 : 0
  target_group_arn = concat(aws_lb_target_group.grafana.*.arn, [""])[0]
  target_id        = module.grafana.private_ip[0]
  port             = 443
}


data "template_file" "agentcontrollerblock" {
  count    = var.instance_count
  template = <<-EOT
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${format("%03d", count.index)}.url = $${url}
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${format("%03d", count.index)}.weight = 1
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${format("%03d", count.index)}.agents = 2
EOT

  vars = {
    url = "https://${aws_lb.this.dns_name}:${aws_lb_listener.this[count.index].port}"
  }
}

data "template_file" "mastercontroller_properties" {
  template = "${file("${path.module}/masterconfig.tpl")}"
  vars = {
    agentcontrollerblock = join("", data.template_file.agentcontrollerblock.*.rendered)
    password             = var.password
  }
}
