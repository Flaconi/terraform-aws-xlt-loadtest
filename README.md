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

  # local_network = "10.0.0.0/16"
  # instance_type = "c4.2xlarge"

  # allowed_networks = "ip/32"
}

```

<!-- TFDOCS_HEADER_START -->


<!-- TFDOCS_HEADER_END -->

<!-- TFDOCS_PROVIDER_START -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.14 |

<!-- TFDOCS_PROVIDER_END -->

<!-- TFDOCS_REQUIREMENTS_START -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.14 |

<!-- TFDOCS_REQUIREMENTS_END -->

<!-- TFDOCS_INPUTS_START -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name used for further interpolation

Type: `string`

### <a name="input_allowed_networks"></a> [allowed\_networks](#input\_allowed\_networks)

Description: The allowed networks IP/32

Type: `list(string)`

### <a name="input_password"></a> [password](#input\_password)

Description: The password to use

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_start_port_services"></a> [start\_port\_services](#input\_start\_port\_services)

Description: The first agent of many will be exposed at port 5000 of the NLB, the second on 5001 etc.etc.

Type: `number`

Default: `5000`

### <a name="input_local_network"></a> [local\_network](#input\_local\_network)

Description: The vpc network

Type: `string`

Default: `"10.0.0.0/16"`

### <a name="input_keyname"></a> [keyname](#input\_keyname)

Description: The existing keyname of the keypair used for connecting with ssh to the agents

Type: `string`

Default: `""`

### <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type)

Description: The default instance\_type

Type: `string`

Default: `"c5.2xlarge"`

### <a name="input_ami"></a> [ami](#input\_ami)

Description: The AMI used for the agents

Type: `string`

Default: `"ami-01cd2bce70ccf6df4"`

### <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count)

Description: The amount of instances to start

Type: `string`

Default: `2`

### <a name="input_instance_count_per_lb"></a> [instance\_count\_per\_lb](#input\_instance\_count\_per\_lb)

Description: The amount of instances per lb

Type: `string`

Default: `50`

### <a name="input_grafana_enabled"></a> [grafana\_enabled](#input\_grafana\_enabled)

Description: Do we create a custom Grafana instance

Type: `bool`

Default: `false`

### <a name="input_grafana_ami"></a> [grafana\_ami](#input\_grafana\_ami)

Description: The grafana ami (required if grafana\_enabled is set to true)

Type: `string`

Default: `"ami-0fc36223101444802"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to add

Type: `map(string)`

Default: `{}`

<!-- TFDOCS_INPUTS_END -->

<!-- TFDOCS_OUTPUTS_START -->
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lb_host"></a> [lb\_host](#output\_lb\_host) | n/a |
| <a name="output_master_controller_properties"></a> [master\_controller\_properties](#output\_master\_controller\_properties) | n/a |
| <a name="output_reporting_host"></a> [reporting\_host](#output\_reporting\_host) | n/a |
| <a name="output_vpc_nat_eips"></a> [vpc\_nat\_eips](#output\_vpc\_nat\_eips) | n/a |

<!-- TFDOCS_OUTPUTS_END -->



## License

[MIT](LICENSE)

Copyright (c) 2019-2023 [Flaconi GmbH](https://github.com/Flaconi)
