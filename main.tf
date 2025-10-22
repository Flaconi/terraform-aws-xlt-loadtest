module "vpc" {
  create_vpc         = var.create_cluster
  source             = "terraform-aws-modules/vpc/aws"
  version            = "6.4.1"
  name               = "xlt-${var.name}"
  cidr               = var.local_network
  azs                = ["eu-central-1a"]
  private_subnets    = [local.private_subnet]
  public_subnets     = [local.public_subnet]
  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags               = local.tags
}

# Master controller security group
module "mc_sg" {
  create      = var.create_cluster
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.3.1"
  name        = "xlt-${var.name}-mc-sg"
  description = "Security group for xlt load test master controller"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress_with_cidr_blocks = [
    for cidr in var.ssh_allowed_cidr_blocks : {
      description = "allow ssh"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = cidr
    }
  ]

  egress_with_cidr_blocks = [
    {
      description = "allow outbound"
      protocol    = "-1"
      from_port   = -1
      to_port     = -1
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

# SSH key pair for connecting the master controller
module "key_pair" {
  create               = var.create_cluster
  source               = "terraform-aws-modules/key-pair/aws"
  version              = "2.1.1"
  key_name             = "xlt-${var.name}-key-pair"
  create_private_key   = true
  private_key_rsa_bits = 2048
  tags                 = local.tags
}

# SSH private key file
resource "local_file" "key_pair_pem" {
  count           = var.create_cluster ? 1 : 0
  filename        = "output/xlt-${var.name}.pem"
  content         = module.key_pair.private_key_pem
  file_permission = "0400"
}

# Master controller ec2 instance
module "master_controller" {
  create                      = var.create_cluster
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "6.1.3"
  name                        = "xlt-${var.name}-master-controller"
  ami                         = var.master_controller_ami
  instance_type               = var.master_controller_instance_type
  key_name                    = module.key_pair.key_pair_name
  monitoring                  = true
  vpc_security_group_ids      = [module.mc_sg.security_group_id]
  subnet_id                   = var.create_cluster ? module.vpc.public_subnets[0] : null
  create_security_group       = false
  create_eip                  = true
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  tags                        = merge(local.tags, { "User-Data-Hash" = md5(local.user_data) })
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for the xlt-${var.name}-master-controller"
  iam_role_path               = "/xlt/"
  iam_role_policies = merge(
    {},
    var.create_cluster && var.create_report_bucket ? { S3Sync = aws_iam_policy.mc_iam_policy_s3_sync[0].arn } : {}
  )
}

# Waits until the master controller setup script finishes
resource "null_resource" "wait_master_controller" {
  count      = var.create_cluster ? 1 : 0
  depends_on = [module.master_controller]
  triggers = {
    master_controller_user_data_md5 = module.master_controller.tags_all["User-Data-Hash"]
  }

  connection {
    type        = local.master_controller_ssh.type
    user        = local.master_controller_ssh.user
    host        = local.master_controller_ssh.host
    private_key = file(local.master_controller_ssh.private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }
}

# Master controller properties file
resource "local_file" "master_controller_properties" {
  count           = var.create_cluster ? 1 : 0
  depends_on      = [module.master_controller, module.agents]
  filename        = "output/mastercontroller.properties"
  file_permission = "0666"

  content = templatefile("${path.module}/templates/masterconfig.tftpl", {
    agents   = var.create_cluster ? module.agents : tomap([])
    password = var.password
  })
}

# Copies the master controller properties to the ec2 instance
resource "null_resource" "copy_master_controller_properties" {
  count      = var.create_cluster ? 1 : 0
  depends_on = [module.master_controller, null_resource.wait_master_controller]
  triggers = {
    master_controller_properties_md5 = local_file.master_controller_properties[0].content_md5
    master_controller_user_data_md5  = module.master_controller.tags_all["User-Data-Hash"]
  }

  connection {
    type        = local.master_controller_ssh.type
    user        = local.master_controller_ssh.user
    host        = local.master_controller_ssh.host
    private_key = file(local.master_controller_ssh.private_key)
  }

  provisioner "file" {
    source      = local_file.master_controller_properties[0].filename
    destination = "${local.xlt_path}/config/mastercontroller.properties"
  }
}
