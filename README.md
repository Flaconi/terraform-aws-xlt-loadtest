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

  # grafana_ami = "ami-0fc36223101444802"
}

```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allowed\_networks | The allowed networks IP/32 | list(string) | n/a | yes |
| name | The name used for further interpolastion | string | n/a | yes |
| password | The password to use | string | n/a | yes |
| ami | The AMI used for the agents | string | `"ami-0f74bf64551726b45"` | no |
| grafana\_ami | The grafana ami (required if grafana_enabled is set to true) | string | `""` | no |
| grafana\_enabled | Do we create a custom Grafana instance | bool | `"false"` | no |
| instance\_count | The amount of instances to start | string | `"2"` | no |
| instance\_type | The default instance_type | string | `"c4.2xlarge"` | no |
| keyname | The existing keyname of the keypair used for connecting with ssh to the agents | string | `""` | no |
| local\_network | The vpc network | string | `"10.0.0.0/16"` | no |
| start\_port\_services | The first agent of many will be exposed at port 5000 of the NLB, the second on 5001 etc.etc. | number | `"5000"` | no |
| start\_port\_ssh | The first ssh of the agents will be exposed at port 6000 of the NLB, the second on 6001 etc.etc. | number | `"6000"` | no |
| tags | The tags to add | map | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| lb\_host |  |
| mastercontroller\_properties |  |
| reporting\_host |  |
| ssh\_ports |  |
| vpc\_nat\_eips |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## License

[MIT](LICENSE)

Copyright (c) 2019 [Flaconi GmbH](https://github.com/Flaconi)
