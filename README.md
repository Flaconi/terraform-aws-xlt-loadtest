# terraform-aws-xlt-loadtest


[![Build Status](https://travis-ci.com/Flaconi/terraform-aws-xlt-loadtest.svg?branch=master)](https://travis-ci.com/Flaconi/terraform-aws-xlt-loadtest)
[![Tag](https://img.shields.io/github/tag/Flaconi/terraform-aws-xlt-loadtest.svg)](https://github.com/Flaconi/terraform-aws-xlt-loadtest/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)


This Terraform module can create typical resources needed for XLT Loadtest

## Usage

### WAF ACL

```hcl
module "terraform-aws-xlt-loadtest" {
  source = "github.com/flaconi/terraform-aws-xlt-loadtest"

  name = "< unique identifier >"
  keyname  = "< your ssh keyname (existing keypair name) >"

  instance_count = 2
  password = xlt1234AbcD

  # start_port_services = "5000"
  # start_port_ssh = "6000"

  # local_network = "10.0.0.0/16"
  # instance_type = "c4.2xlarge"

  # allowed_networks = "ip/32"
}

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ec2_sg"></a> [ec2\_sg](#module\_ec2\_sg) | terraform-aws-modules/security-group/aws | 4.13.0 |
| <a name="module_grafana"></a> [grafana](#module\_grafana) | terraform-aws-modules/ec2-instance/aws | 4.1.4 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 3.14.4 |
| <a name="module_xceptance_cluster"></a> [xceptance\_cluster](#module\_xceptance\_cluster) | terraform-aws-modules/ec2-instance/aws | 4.1.4 |

## Resources

| Name | Type |
|------|------|
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_target_group_attachment.agents](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [aws_lb_target_group_attachment.grafana](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |
| [template_file.agentcontrollerblock](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.mastercontroller_properties](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_networks"></a> [allowed\_networks](#input\_allowed\_networks) | The allowed networks IP/32 | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name used for further interpolation | `string` | n/a | yes |
| <a name="input_password"></a> [password](#input\_password) | The password to use | `string` | n/a | yes |
| <a name="input_ami"></a> [ami](#input\_ami) | The AMI used for the agents | `string` | `"ami-0b701f8f19be222c6"` | no |
| <a name="input_grafana_ami"></a> [grafana\_ami](#input\_grafana\_ami) | The grafana ami (required if grafana\_enabled is set to true) | `string` | `"ami-0fc36223101444802"` | no |
| <a name="input_grafana_enabled"></a> [grafana\_enabled](#input\_grafana\_enabled) | Do we create a custom Grafana instance | `bool` | `false` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | The amount of instances to start | `string` | `2` | no |
| <a name="input_instance_count_per_lb"></a> [instance\_count\_per\_lb](#input\_instance\_count\_per\_lb) | The amount of instances per lb | `string` | `50` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The default instance\_type | `string` | `"c5.2xlarge"` | no |
| <a name="input_keyname"></a> [keyname](#input\_keyname) | The existing keyname of the keypair used for connecting with ssh to the agents | `string` | `""` | no |
| <a name="input_local_network"></a> [local\_network](#input\_local\_network) | The vpc network | `string` | `"10.0.0.0/16"` | no |
| <a name="input_start_port_services"></a> [start\_port\_services](#input\_start\_port\_services) | The first agent of many will be exposed at port 5000 of the NLB, the second on 5001 etc.etc. | `number` | `5000` | no |
| <a name="input_start_port_ssh"></a> [start\_port\_ssh](#input\_start\_port\_ssh) | The first ssh of the agents will be exposed at port 6000 of the NLB, the second on 6001 etc.etc. | `number` | `6000` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to add | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_host"></a> [lb\_host](#output\_lb\_host) | n/a |
| <a name="output_mastercontroller_properties"></a> [mastercontroller\_properties](#output\_mastercontroller\_properties) | n/a |
| <a name="output_reporting_host"></a> [reporting\_host](#output\_reporting\_host) | n/a |
| <a name="output_vpc_nat_eips"></a> [vpc\_nat\_eips](#output\_vpc\_nat\_eips) | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## License

[MIT](LICENSE)

Copyright (c) 2019 [Flaconi GmbH](https://github.com/Flaconi)
