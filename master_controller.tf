locals {
  xlt_version                       = "9.1.2"
  master_controller_create          = var.master_controller_create && var.instance_count > 0
  master_controller_create_key_pair = local.master_controller_create && var.keyname == null
  master_controller_key_pair        = local.master_controller_create_key_pair ? module.master_controller_key_pair.key_pair_name : var.keyname

  user_data = <<-EOT
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install java-21-amazon-corretto-devel -y
    sudo dnf install git -y
    cd /home/ec2-user/
    wget https://lab.xceptance.de/releases/xlt/${local.xlt_version}/xlt-${local.xlt_version}.zip
    unzip xlt-${local.xlt_version}.zip
    git clone -b ${var.master_controller_xlt_tests_branch} https://${var.master_controller_github_token}@github.com/Flaconi/xlt-load-test-lite.git xlt-tests
  EOT
}

module "master_controller_key_pair" {
  source               = "terraform-aws-modules/key-pair/aws"
  version              = "2.1.0"
  create               = local.master_controller_create_key_pair
  key_name             = "xlt-${var.name}-master-controller"
  create_private_key   = true
  private_key_rsa_bits = 2048
}

module "master_controller" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "6.1.1"
  create                      = local.master_controller_create
  name                        = "xlt-${var.name}-master-controller"
  ami                         = var.master_controller_ami
  instance_type               = var.master_controller_instance_type
  key_name                    = local.master_controller_key_pair
  monitoring                  = true
  vpc_security_group_ids      = [module.ec2_sg.security_group_id]
  subnet_id                   = module.vpc.private_subnets[0]
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  tags                        = local.tags
}

resource "aws_lb_target_group" "master_controller" {
  count                = local.master_controller_create ? 1 : 0
  name_prefix          = "xltmc"
  port                 = "22"
  protocol             = "TCP"
  vpc_id               = module.vpc.vpc_id
  target_type          = "ip"
  deregistration_delay = "10"
  tags                 = local.tags

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 2
    interval            = 10
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "master_controller" {
  count            = local.master_controller_create ? 1 : 0
  target_group_arn = aws_lb_target_group.master_controller[0].arn
  target_id        = module.master_controller.private_ip
  port             = 22
}

resource "aws_lb_listener" "master_controller" {
  count             = local.master_controller_create ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = var.master_controller_ssh_port
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.master_controller[0].arn
    type             = "forward"
  }
}

resource "local_file" "master_controller_key_pair_pem" {
  count           = local.master_controller_create_key_pair ? 1 : 0
  filename        = "output/xlt-${var.name}.pem"
  content         = module.master_controller_key_pair.private_key_pem
  file_permission = "0400"
}

resource "local_file" "master_controller_properties" {
  count           = var.instance_count > 0 ? 1 : 0
  filename        = "output/mastercontroller.properties"
  file_permission = "0666"

  content = templatefile("${path.module}/masterconfig.tftpl", {
    agent_controller_block = join("", local.agent_controller_blocks)
    password               = var.password
  })
}
