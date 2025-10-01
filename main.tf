locals {
  xlt_version    = "9.1.2"
  pad_length     = length(tostring(var.agent_count))
  private_subnet = cidrsubnet(var.local_network, 8, 1)
  public_subnet  = cidrsubnet(var.local_network, 8, 101)

  tags = merge(
    var.tags,
    {
      "Name"        = "xlt-${var.name}"
      "Environment" = "load-test"
    },
  )

  user_data = <<-EOT
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install java-21-amazon-corretto-devel -y
    sudo dnf install git -y
    sudo dnf install maven -y
    cd /home/ec2-user
    wget https://lab.xceptance.de/releases/xlt/${local.xlt_version}/xlt-${local.xlt_version}.zip
    unzip xlt-${local.xlt_version}.zip
    git clone -b ${var.branch_name} https://${var.github_token}@github.com/Flaconi/xlt-load-test-lite.git xlt-tests
    cd xlt-tests
    export JAVA_HOME="/usr/lib/jvm/java-21-amazon-corretto.aarch64"
    mvn install
    cd ..
    sudo chown -R ec2-user:ec2-user .
    touch -- '@@@ BUILD DONE @@@'
  EOT

  agent_controllers = [for index, agent in module.agents : <<-EOT
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.url = https://${agent.private_ip}:8500
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.weight = 1
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.agents = 2
    EOT
  ]
}

module "vpc" {
  source             = "terraform-aws-modules/vpc/aws"
  version            = "6.4.0"
  name               = "xlt-${var.name}"
  cidr               = var.local_network
  azs                = ["eu-central-1a"]
  private_subnets    = [local.private_subnet]
  public_subnets     = [local.public_subnet]
  enable_nat_gateway = true
  enable_vpn_gateway = false
  tags               = local.tags
}

module "mc_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.3.0"
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

module "agent_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "5.3.0"
  name        = "xlt-${var.name}-agent-sg"
  description = "Security group for xlt load test agent"
  vpc_id      = module.vpc.vpc_id
  tags        = local.tags

  ingress_with_source_security_group_id = [
    {
      description              = "allow xlt connection from mc"
      protocol                 = "tcp"
      from_port                = 8500
      to_port                  = 8500
      source_security_group_id = module.mc_sg.security_group_id
    },
    {
      description              = "allow ssh connection from mc"
      protocol                 = "tcp"
      from_port                = 22
      to_port                  = 22
      source_security_group_id = module.mc_sg.security_group_id
    },
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

module "key_pair" {
  source               = "terraform-aws-modules/key-pair/aws"
  version              = "2.1.0"
  key_name             = "xlt-${var.name}-key-pair"
  create_private_key   = true
  private_key_rsa_bits = 2048
  tags                 = local.tags
}

module "master_controller" {
  source                      = "terraform-aws-modules/ec2-instance/aws"
  version                     = "6.1.1"
  name                        = "xlt-${var.name}-master-controller"
  ami                         = var.master_controller_ami
  instance_type               = var.master_controller_instance_type
  key_name                    = module.key_pair.key_pair_name
  monitoring                  = true
  vpc_security_group_ids      = [module.mc_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  create_security_group       = false
  create_eip                  = true
  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true
  tags                        = local.tags
}

resource "null_resource" "wait_master_controller" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = module.master_controller.public_ip
    private_key = file(local_file.key_pair_pem.filename)
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
  }
}

resource "null_resource" "copy_master_controller_properties" {
  depends_on = [null_resource.wait_master_controller]
  triggers = {
    master_controller_properties_file = local_file.master_controller_properties.content_md5
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    host        = module.master_controller.public_ip
    private_key = file(local_file.key_pair_pem.filename)
  }

  provisioner "file" {
    source      = local_file.master_controller_properties.filename
    destination = "/home/ec2-user/xlt-${local.xlt_version}/config/mastercontroller.properties"
  }
}

module "agents" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "6.1.1"
  count                  = var.agent_count
  name                   = format("xlt-${var.name}-%0${local.pad_length}s", count.index)
  ami                    = var.agent_ami
  instance_type          = var.agent_instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.agent_sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0]
  create_security_group  = false
  user_data              = "{\"acPassword\":\"${var.password}\",\"hostData\":\"\"}"
  tags                   = local.tags
}

resource "local_file" "key_pair_pem" {
  filename        = "output/xlt-${var.name}.pem"
  content         = module.key_pair.private_key_pem
  file_permission = "0400"
}

resource "local_file" "master_controller_properties" {
  filename        = "output/mastercontroller.properties"
  file_permission = "0666"

  content = templatefile("${path.module}/masterconfig.tftpl", {
    agent_controller_block = join("", local.agent_controllers)
    password               = var.password
  })
}
