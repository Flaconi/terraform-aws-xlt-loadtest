output "lb_host" {
  value = aws_lb.this.*.dns_name
}

output "master_controller_properties" {
  value = templatefile("${path.module}/masterconfig.tftpl", {
    agent_controller_block = join("", local.agent_controller_blocks)
    password               = var.password
  })
}

output "reporting_host" {
  value = var.grafana_enabled ? "xlt.reporting.graphite.host = ${local.graphite_host}" : "# Not enabled"
}

output "vpc_nat_eips" {
  value = module.vpc.nat_public_ips
}
