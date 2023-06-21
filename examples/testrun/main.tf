provider "aws" {
  region = "eu-central-1"
}

module "cluster" {
  source                = "./../.."
  name                  = "xlt-example"
  instance_count        = 1
  instance_count_per_lb = 2
  password              = "xlt1234AbcD"
  allowed_networks      = ["0.0.0.0/0"]
  grafana_enabled       = true
  keyname               = "your.key"
}

output "lb_host" { value = module.cluster.lb_host }
output "master_controller_properties" { value = module.cluster.master_controller_properties }
output "reporting_host" { value = module.cluster.reporting_host }
output "vpc_nat_eips" { value = module.cluster.vpc_nat_eips }
