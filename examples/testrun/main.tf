provider "aws" {
  region = "eu-central-1"
}

module "cluster" {
  source       = "../../"
  name         = "test-run"
  agent_count  = 2
  password     = "password"
  github_token = "github_token"
  branch_name  = "master"
}

output "ssh_commands" {
  value = module.cluster.ssh_commands
}
