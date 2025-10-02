output "ssh_commands" {
  value = {
    "ssh to the master controller"     = "ssh -i ${local_file.key_pair_pem.filename} ec2-user@${module.master_controller.public_ip}"
    "copy mastercontroller.properties" = "scp -i ${local_file.key_pair_pem.filename} output/mastercontroller.properties ec2-user@${module.master_controller.public_ip}:~/xlt-${local.xlt_version}/config/mastercontroller.properties"
    "sync reports"                     = "aws s3 sync ${local.xlt_path}/reports s3://${module.report.s3_bucket_id}"
  }
}

output "report_url" {
  value = "http://${module.report.s3_bucket_website_endpoint}"
}
