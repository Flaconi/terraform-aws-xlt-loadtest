# terraform-aws-xlt-loadtest


[![Build Status](https://travis-ci.com/Flaconi/terraform-aws-xlt-loadtest.svg?branch=master)](https://travis-ci.com/Flaconi/terraform-aws-xlt-loadtest)
[![Tag](https://img.shields.io/github/tag/Flaconi/terraform-aws-xlt-loadtest.svg)](https://github.com/Flaconi/terraform-aws-xlt-loadtest/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)


This Terraform module automates the setup of a complete Xceptance load test cluster on AWS. It handles everything from provisioning the master controller and agent instances to configuring them, checking out your test sources from GitHub, and building them on the master controller.

## How to use

### Generate a GitHub Fine-Grained Access Token 🔑
To check out the XLT tests on the master controller, you need to create a fine-grained personal access token with specific read-only permissions.
1.  **Navigate to the token creation page in your GitHub settings.**
    - You can use this direct link: [**Generate new token**](https://github.com/settings/personal-access-tokens/new).
2.  **Configure the new token with the following details:**
    - **Token name**: Enter a descriptive name, like `xlt-master-controller-access`.
    - **Expiration**: Set an appropriate expiration date for the token.
    - **Resource owner**: Select `Flaconi`.
    - **Repository access**: Choose **Only selected repositories** and then select `Flaconi/xlt-load-test-lite` from the repository list.
    - **Permissions**:
        - Under the "Repository permissions" section, find **Contents** and set its access to **Read-only**.
        - _GitHub will automatically add the required "Metadata (Read-only)" permission for you._
3.  **Generate and save the token.**
    - Click the **Generate token** button at the bottom of the page.
    > **⚠️ Important**
    > Copy the generated token immediately and store it in a secure place. You will **not** be able to see it again after leaving the page. This token is required to configure the master controller.

### Deploying the Load Test Cluster with Terraform 🚀
#### 1. Prepare Your Workspace
First, clone the Terraform module repository from GitHub and prepare a working directory by copying the provided example.
```bash
# Clone the repository
git clone git@github.com:Flaconi/terraform-aws-xlt-loadtest.git

# Navigate into the repository directory
cd terraform-aws-xlt-loadtest

# Create a working directory for your configuration
mkdir workdir

# Copy the example configuration into your workdir
cp examples/testrun/main.tf workdir/

# Navigate into your new working directory
cd workdir
```
#### Step 2: Configure Your Cluster ⚙️
Next, open the `main.tf` file in your `workdir` and adjust the following parameters to match your requirements:
- **`source`**: Update the relative path to the module's source directory.
- **`name`**: Provide a short, descriptive name to identify your cluster.
- **`agent_count`**: Set the number of load test agents you want to deploy.
- **`password`**: Define a secure password for the Agent Controller.
- **`github_token`**: Paste the fine-grained GitHub access token you created previously.
- **`branch_name`**: Specify the name of the Git branch containing the test sources you want to check out.
#### 3. Launch the Infrastructure
With your configuration complete, use the standard Terraform workflow to initialize and deploy the cluster.
```bash
# 1. Initialize the module
terraform init

# 2. (Optional) Review the execution plan
terraform plan

# 3. Create the resources on AWS
terraform apply
```
#### Step 4: Review Your Outputs and Local Files 📝
After `terraform apply` completes, you'll get two types of output: values printed to your terminal and essential files saved to a local directory. They contain crucial information for accessing and managing your cluster.
##### Terminal Outputs
- **`ssh_commands`**: This structured output provides you with:
    - The **SSH command** to connect directly to the master controller.
    - A **`scp` command** to copy the master controller's properties file.
    - An **AWS CLI command** to sync test reports from the master controller to an S3 bucket.
- **`report_url`**: This is the direct **URL** where you can access and view the test result reports.
##### Local Output Files
The module will also create a new **`output`** directory inside your `workdir`. This folder contains crucial files for accessing the cluster:
-   The **private key** file needed for the SSH connection.
-   A copy of the generated **`mastercontroller.properties`** file.

### Running Your Load Test ⚡️
After your cluster has been successfully created with Terraform, follow these steps to connect to the master controller and execute a load test.
#### 1. Connect to the Master Controller 🖥️
Use the `ssh` command provided in the `ssh_commands` output from your Terraform `apply`. This will log you into the master controller instance.
```bash
# Example command from your Terraform output
ssh -i /path/to/your/key.pem ec2-user@ec2-xx-xx-xx-xx.compute-1.amazonaws.com
```
#### 2. Launch the XLT Master Controller
Once you are connected via SSH, navigate to the Xceptance LoadTest (XLT) directory and start the interactive master controller shell.
```bash
# Navigate to the XLT installation directory
cd xlt-9.1.2/

# Start the master controller
./bin/mastercontroller.sh
```
#### 3. Execute the Test in Interactive Mode
You are now inside the XLT master controller's command shell. From here, you can manage the agents and the test run. The typical workflow involves the following commands:
1.  **Ping the agents** to confirm they are online and connected.
2.  **Upload your test suite** to all connected agents.
3.  **Start the load test**.
4.  **Download the results** from the agents after the test is complete.
5.  **Create the HTML report** from the downloaded result data.
#### 4. Access the Test Report 📊
The test report is automatically uploaded to the S3 bucket configured by the Terraform module. You can view it directly using the **`report_url`** provided in the Terraform output.
> **For Advanced Usage**
>
> This guide covers the basic interactive workflow. For a complete list of commands and more advanced scenarios, please refer to the official Xceptance documentation:
>
> **[XLT Manual: Test Execution (Interactive Mode)](https://docs.xceptance.com/xlt/load-testing/manual/310-test-execution/#interactive-mode)**

### Destroying the Load Test Cluster 💣
When you're finished testing, you can remove all the created AWS resources to prevent ongoing costs.
> **⚠️ Important: Report Deletion**
> Running the `destroy` command will permanently delete all provisioned resources, **including the S3 bucket and any test reports** synchronized to it. Please make sure you have saved any reports you need to keep before proceeding.
To destroy the cluster, navigate to your `workdir` and run the standard Terraform command:

```bash
# This will prompt for confirmation before deleting all resources.
terraform destroy
```

<!-- TFDOCS_HEADER_START -->


<!-- TFDOCS_HEADER_END -->

<!-- TFDOCS_PROVIDER_START -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.14.1 |
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
| <a name="output_report_url"></a> [report\_url](#output\_report\_url) | n/a |
| <a name="output_ssh_commands"></a> [ssh\_commands](#output\_ssh\_commands) | n/a |

<!-- TFDOCS_OUTPUTS_END -->



## License

[MIT](LICENSE)

Copyright (c) 2019-2023 [Flaconi GmbH](https://github.com/Flaconi)
