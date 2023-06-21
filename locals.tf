locals {
  private_subnet        = cidrsubnet(var.local_network, 8, 1)
  public_subnet         = cidrsubnet(var.local_network, 8, 101)
  graphite_host         = cidrhost(local.private_subnet, 200)
  nlb_count             = ceil((var.instance_count + (var.grafana_enabled ? 1 : 0)) / var.instance_count_per_lb)
  instance_count_per_lb = min(49, var.instance_count_per_lb)

  tags = merge(
    var.tags,
    {
      "Name"        = var.name
      "Environment" = "xlt"
    },
  )

  agent_controller_urls = { for id in range(var.instance_count) :
    format("%03d", id) => format("https://%s:%s",
      aws_lb.this[ceil((id + 1) / local.instance_count_per_lb) - 1].dns_name,
      aws_lb_listener.this[id].port
    )
  }
  agent_controller_blocks = [for index, url in local.agent_controller_urls :
    <<-EOT
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.url = ${url}
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.weight = 1
com.xceptance.xlt.mastercontroller.agentcontrollers.ac${index}.agents = 2
EOT
  ]
}
