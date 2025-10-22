output "ssh_commands" {
  value = merge({},
    var.create_cluster ? {
      "ssh to the master controller (execute local)"     = "ssh -i ${local_file.key_pair_pem[0].filename} ec2-user@${module.master_controller.public_ip}"
      "copy mastercontroller.properties (execute local)" = "scp -i ${local_file.key_pair_pem[0].filename} output/mastercontroller.properties ec2-user@${module.master_controller.public_ip}:~/xlt-${local.xlt_version}/config/mastercontroller.properties"
    } : {},
    var.create_cluster && var.create_report_bucket ? {
      "sync reports to the report host (execute remote)" = "aws s3 sync ${local.xlt_path}/reports s3://${module.report.s3_bucket_id}"
      "sync reports to the local (execute local)"        = "aws s3 sync s3://${module.report.s3_bucket_id} ./output/reports/"
    } : {}
  )
}

output "report_url" {
  value = var.create_report_bucket ? "http://${module.report.s3_bucket_website_endpoint}" : null
}
