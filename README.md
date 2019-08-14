# terraform-aws-xlt-loadtest

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
| allowed\_networks |  | string | `"185.28.184.194/32"` | no |
| ami |  | string | `"ami-0f74bf64551726b45"` | no |
| grafana\_ami |  | string | `"ami-0fc36223101444802"` | no |
| instance\_count |  | string | `"2"` | no |
| instance\_type |  | string | `"c4.2xlarge"` | no |
| keyname |  | string | `"maarten"` | no |
| local\_network |  | string | `"10.0.0.0/16"` | no |
| name |  | string | `"thename"` | no |
| password |  | string | `"lalala"` | no |
| start\_port\_services |  | number | `"5000"` | no |
| start\_port\_ssh |  | number | `"6000"` | no |

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
