locals {
  xlt_version         = "9.1.2"
  home_path           = "/home/ec2-user"
  xlt_path            = "${local.home_path}/xlt-${local.xlt_version}"
  pad_length          = length(tostring(var.agent_count))
  private_subnet      = cidrsubnet(var.local_network, 8, 1)
  public_subnet       = cidrsubnet(var.local_network, 8, 101)
  reports_bucket_name = "flaconi-xlt-${var.name}-report"

  tags = merge(
    var.tags,
    {
      "Name"        = "xlt-${var.name}"
      "Environment" = "load-test"
    },
  )

  # Master controller setup scripts
  generate_reports_index_html = <<-EOT
    #!/bin/bash
    cd ${local.xlt_path}/reports
    list=$(find . -mindepth 1 -maxdepth 1 -type d ! -name ".*" -printf "<li><a href=\"http://${module.report.s3_bucket_website_endpoint}/%f\">%f</a></li>\n")
    echo -e "<html>\n<body>\n<ul>\n$${list}</ul>\n</body>\n</html>" > index.html
  EOT

  user_data = <<-EOT
    #!/bin/bash
    sudo dnf update -y
    sudo dnf install java-21-amazon-corretto-devel -y
    sudo dnf install git -y
    sudo dnf install maven -y
    sudo dnf install cronie -y

    cd ${local.home_path}

    wget https://lab.xceptance.de/releases/xlt/${local.xlt_version}/xlt-${local.xlt_version}.zip
    unzip xlt-${local.xlt_version}.zip

    git clone -b ${var.branch_name} https://${var.github_token}@github.com/Flaconi/xlt-load-test-lite.git xlt-tests
    git config pull.rebase true
    cd xlt-tests
    export JAVA_HOME="/usr/lib/jvm/java-21-amazon-corretto.aarch64"
    mvn install

    cd ..

    mkdir scripts
    cat > scripts/generate_reports_index_html.sh <<'EOF'
    ${local.generate_reports_index_html}
    EOF
    chmod +x scripts/generate_reports_index_html.sh

    sudo chown -R ec2-user:ec2-user .

    sudo systemctl enable crond.service
    sudo systemctl start crond.service
    echo "\
    * * * * * ${local.home_path}/scripts/generate_reports_index_html.sh
    * * * * * aws s3 sync ${local.xlt_path}/reports s3://${module.report.s3_bucket_id} --quiet" | sudo crontab -u ec2-user -

    touch -- '@@@ BUILD DONE @@@'
  EOT

  # Master controller agent configuration template
  agent_controllers = [for index, agent in module.agents : <<-EOT
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.url = https://${agent.private_ip}:8500
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.weight = 1
      com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.agents = 2
    EOT
  ]

  # Master controller ssh connection
  master_controller_ssh = {
    type        = "ssh"
    user        = "ec2-user"
    host        = module.master_controller.public_ip
    private_key = local_file.key_pair_pem.filename
  }
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

# Master controller security group
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

# Agent security group
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

# SSH key for connecting the master controller
module "key_pair" {
  source               = "terraform-aws-modules/key-pair/aws"
  version              = "2.1.0"
  key_name             = "xlt-${var.name}-key-pair"
  create_private_key   = true
  private_key_rsa_bits = 2048
  tags                 = local.tags
}

# IAM Policy for syncing loast test reports to s3
resource "aws_iam_policy" "mc_iam_policy_s3_sync" {
  name        = "xlt-${var.name}-master-controller-iam-policy-s3-sync"
  path        = "/"
  description = "IAM role policy for s3 sync"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObjectAcl",
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${local.reports_bucket_name}",
          "arn:aws:s3:::${local.reports_bucket_name}/*"
        ]
      },
    ]
  })
}

# Master controller ec2 instance
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
  tags                        = merge(local.tags, { "User-Data-Hash" = md5(local.user_data) })
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for the xlt-${var.name}-master-controller"
  iam_role_policies = {
    S3Sync = aws_iam_policy.mc_iam_policy_s3_sync.arn
  }
}

# Waits until the master controller setup script finishes
resource "null_resource" "wait_master_controller" {
  depends_on = [module.master_controller]
  triggers = {
    master_controller_tags = module.master_controller.tags_all["User-Data-Hash"]
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

# Copies the master controller properties to the ec2 instance
resource "null_resource" "copy_master_controller_properties" {
  depends_on = [module.master_controller, null_resource.wait_master_controller]
  triggers = {
    master_controller_properties_file = local_file.master_controller_properties.content_md5
  }

  connection {
    type        = local.master_controller_ssh.type
    user        = local.master_controller_ssh.user
    host        = local.master_controller_ssh.host
    private_key = file(local.master_controller_ssh.private_key)
  }

  provisioner "file" {
    source      = local_file.master_controller_properties.filename
    destination = "${local.xlt_path}/config/mastercontroller.properties"
  }
}

# Agents
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

# S3 bucket to store/serve load test reports
module "report" {
  source                   = "terraform-aws-modules/s3-bucket/aws"
  version                  = "5.7.0"
  bucket                   = local.reports_bucket_name
  force_destroy            = true
  acl                      = "public-read"
  block_public_acls        = false
  block_public_policy      = false
  ignore_public_acls       = false
  restrict_public_buckets  = false
  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"
  tags                     = local.tags

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${local.reports_bucket_name}/*"
      },
    ]
  })

  website = {
    index_document = "index.html"
  }

  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      expose_headers  = []
    }
  ]
}

# SSH private key file
resource "local_file" "key_pair_pem" {
  filename        = "output/xlt-${var.name}.pem"
  content         = module.key_pair.private_key_pem
  file_permission = "0400"
}

# Master controller properties file
resource "local_file" "master_controller_properties" {
  filename        = "output/mastercontroller.properties"
  file_permission = "0666"

  content = templatefile("${path.module}/templates/masterconfig.tftpl", {
    agent_controller_block = join("", local.agent_controllers)
    password               = var.password
  })
}
