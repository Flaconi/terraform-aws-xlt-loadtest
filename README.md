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
| <a name="provider_local"></a> [local](#provider\_local) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3.2 |

<!-- TFDOCS_PROVIDER_END -->

<!-- TFDOCS_REQUIREMENTS_START -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.14 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3.2 |

<!-- TFDOCS_REQUIREMENTS_END -->

<!-- TFDOCS_INPUTS_START -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name used for further interpolation

Type: `string`

### <a name="input_password"></a> [password](#input\_password)

Description: The password to use

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_local_network"></a> [local\_network](#input\_local\_network)

Description: The vpc network

Type: `string`

Default: `"10.0.0.0/16"`

### <a name="input_master_controller_ami"></a> [master\_controller\_ami](#input\_master\_controller\_ami)

Description: The AMI used for the master controller

Type: `string`

Default: `"ami-00544f9ad8d9a0458"`

### <a name="input_master_controller_instance_type"></a> [master\_controller\_instance\_type](#input\_master\_controller\_instance\_type)

Description: The instance\_type used for the master controller

Type: `string`

Default: `"c8g.2xlarge"`

### <a name="input_agent_ami"></a> [agent\_ami](#input\_agent\_ami)

Description: The AMI used for the agents

Type: `string`

Default: `"ami-0db8929bf1d58c81a"`

### <a name="input_agent_instance_type"></a> [agent\_instance\_type](#input\_agent\_instance\_type)

Description: The instance\_type used for the agents

Type: `string`

Default: `"c8g.2xlarge"`

### <a name="input_agent_count"></a> [agent\_count](#input\_agent\_count)

Description: The amount of instances to start

Type: `string`

Default: `2`

### <a name="input_ssh_allowed_cidr_blocks"></a> [ssh\_allowed\_cidr\_blocks](#input\_ssh\_allowed\_cidr\_blocks)

Description: The cidr blocks alloed ssh

Type: `list(string)`

Default:

```json
[
  "0.0.0.0/0"
]
```

### <a name="input_github_token"></a> [github\_token](#input\_github\_token)

Description: The Github fine-grained token to checkout the tests

Type: `string`

Default: `""`

### <a name="input_branch_name"></a> [branch\_name](#input\_branch\_name)

Description: The branch name to checkout the tests

Type: `string`

Default: `"master"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: The tags to add

Type: `map(string)`

Default: `{}`

<!-- TFDOCS_INPUTS_END -->

<!-- TFDOCS_OUTPUTS_START -->
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssh_commands"></a> [ssh\_commands](#output\_ssh\_commands) | n/a |

<!-- TFDOCS_OUTPUTS_END -->



## License

[MIT](LICENSE)

Copyright (c) 2019-2023 [Flaconi GmbH](https://github.com/Flaconi)
