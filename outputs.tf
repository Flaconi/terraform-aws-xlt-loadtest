output "lb_host" {
  value = aws_lb.this.*.dns_name
}

output "reporting_host" {
  value = var.grafana_enabled ? "xlt.reporting.graphite.host = ${local.graphite_host}" : "# Not enabled"
}

output "vpc_nat_eips" {
  value = module.vpc.nat_public_ips
}

output "master_controller_ssh_commands" {
  value = local.master_controller_create && local.master_controller_create_key_pair ? {
    "ssh to the master controller" = "ssh -i ${local_file.master_controller_key_pair_pem[0].filename} -p ${var.master_controller_ssh_port} ec2-user@${aws_lb.this[0].dns_name}"
    "copy mastercontroller.properties" = "scp -i ${local_file.master_controller_key_pair_pem[0].filename} -P ${var.master_controller_ssh_port} output/mastercontroller.properties ec2-user@${aws_lb.this[0].dns_name}:~/xlt-${local.xlt_version}/config/mastercontroller.properties"
  } : null
}
