provider "aws" {
  region = "eu-central-1"
}

module "cluster" {
  source                             = "../../"
  name                               = "xlt-example"
  instance_count                     = 1
  instance_count_per_lb              = 2
  allowed_networks                   = ["0.0.0.0/0"]
  password                           = "xlt1234AbcD"
  grafana_enabled                    = false
  master_controller_create           = true
  master_controller_github_token     = "github_token_to_checkout_src"
  master_controller_xlt_tests_branch = "master"
}

output "lb_host" {
  value = module.cluster.lb_host
}

output "reporting_host" {
  value = module.cluster.reporting_host
}

output "vpc_nat_eips" {
  value = module.cluster.vpc_nat_eips
}

output "master_controller_ssh_commands" {
  value = module.cluster.master_controller_ssh_commands
}
