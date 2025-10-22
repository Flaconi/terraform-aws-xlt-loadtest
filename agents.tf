# Agent security group
module "agent_sg" {
  create      = var.create_cluster
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

# Agents
module "agents" {
  depends_on             = [module.vpc]
  create                 = var.create_cluster
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "6.1.1"
  count                  = var.agent_count
  name                   = format("xlt-${var.name}-%0${local.pad_length}s", count.index)
  ami                    = var.agent_ami
  instance_type          = var.agent_instance_type
  key_name               = module.key_pair.key_pair_name
  monitoring             = true
  vpc_security_group_ids = [module.agent_sg.security_group_id]
  subnet_id              = var.create_cluster ? module.vpc.private_subnets[0] : null
  create_security_group  = false
  user_data              = "{\"acPassword\":\"${var.password}\",\"hostData\":\"\"}"
  tags                   = local.tags
}
