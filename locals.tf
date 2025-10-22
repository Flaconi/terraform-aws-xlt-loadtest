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

  user_data = templatefile("${path.module}/templates/userdata.tftpl", {
    home_path                  = local.home_path
    xlt_version                = local.xlt_version
    branch_name                = var.branch_name
    github_token               = var.github_token
    xlt_path                   = local.xlt_path
    s3_bucket_id               = var.create_report_bucket ? module.report.s3_bucket_id : ""
    s3_bucket_website_endpoint = var.create_report_bucket ? module.report.s3_bucket_website_endpoint : ""
  })

  # Master controller ssh connection
  master_controller_ssh = var.create_cluster ? {
    type        = "ssh"
    user        = "ec2-user"
    host        = module.master_controller.public_ip
    private_key = local_file.key_pair_pem[0].filename
  } : null
}
