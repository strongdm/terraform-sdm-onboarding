# Create a strongDM Playground with Terraform

It can take time and patience to set up and test databases, servers, websites, clusters, and gateways in order to see strongDM in action. If you would prefer a simpler approach, you can use Terraform to spin up all of the necessary resources in AWS and set them up in your strongDM Admin UI. The Terraform script and this guide will get you up and running with a variety of users, resources, and gateways to help you to more quickly get hands-on experience and test out strongDM's capabilities.

## Prerequisites

* You will need a strongDM account (if you don't have one, [sign up here](https://www.strongdm.com/signup-contact/))
* You will need [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your computer (a version **less than 0.13**).
* This script needs to be followed using a Linux or macOS device. A Windows-compatible version is pending.
* You will need the `wget` package installed (if you are using macOS, you can acquire it using Homebrew).
* You will need an Amazon Web Services (AWS) account and an API key with permissions sufficient to provision all of the resources you intend to provision ([AWS Dashboard](https://console.aws.amazon.com/ec2/v2/home) > Key Pairs).

> **Warning:** The script will create AWS resources on your account, which will incur AWS costs. Once you're done testing, you will likely want to remove them to prevent unnecessary AWS costs, either manually or with `terraform destroy`. strongDM provides this script as is, and does not accept liability for any alterations to AWS assets or any AWS costs incurred.

## Setup

In order to run the Terraform-powered creation of our strongDM playground, we need to create a few items:

* A strongDM API key
* A main configuration file for our Terraform project
* A module file for our strongDM playground creation

### Create a strongDM API key

Go to your [strongDM Admin UI](https://app.strongdm.com/app/settings). Under **Settings** in the navigation menu, you will see that the first tab is titled **Admin Tokens**. Click **add api key**, give the key a name, and then give it relevant permissions. 

This script will, or can potentially, create and then destroy all of these categories of items. For the purposes of this demo, you might wish to grant the key access to all of these items. There is an option to set the key to expire so that you don't forget to remove it later.

Once you are shown the credentials, be sure to record them somewhere safe, as it will not show them to you again.

### Terraform project configuration file

In the directory where you intend to run your terraform commands, create a `main.tf` file and add the following configuration to it:

```tf
terraform {
  required_version = ">= 0.12.26"
  required_providers {
    aws = ">= 3.0.0"
    sdm = ">= 1.0.12"
  }
}
provider aws {
  region     = local.region
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}
variable AWS_ACCESS_KEY_ID {}
variable AWS_SECRET_ACCESS_KEY {}
locals {
  region = "us-east-2"
}
provider sdm {
  api_access_key = var.SDM_API_ACCESS_KEY
  api_secret_key = var.SDM_API_SECRET_KEY
}
variable SDM_API_ACCESS_KEY {}
variable SDM_API_SECRET_KEY {}
```

* The script requires Terraform version 0.12.x, AWS 3.0.x, and sdm 1.0.x at this time
* You should change the region to whatever AWS region suits your purposes for testing
* You'll be required to enter your AWS credentials and SDM credentials when running Terraform commands with them, so keep those available.

### Customize the Terraform module

Create a file (in this example, we called it `onboarding.tf`) and paste in the module.

```tf
module "strongdm_onboarding" {
  source = "git::https://github.com/strongdm/terraform-sdm-onboarding.git"

  # Prefix will be added to resource names
  prefix = "foo"

  # EKS resources take approximately 20 min
  create_eks               = true
  # Mysql resources take approximately 5 min
  create_mysql             = true
  # RDP resources take approximately 10 min
  create_rdp               = true
  # HTTP resources take approximately 5 min
  create_http              = true
  # Kibana resources take approximately 15 min
  create_kibana            = true
  # Gateways take approximately 5 min
  create_strongdm_gateways = true

  # Leave variables set to null to create resources in default VPC.
  vpc_id     = null
  subnet_ids = null

  # List of existing users to grant resources to
  # NOTE: An error will occur if these users are already assigned to a role in strongDM
  grant_to_existing_users = [
    "admin@example.com",
  ]

  # New accounts to create with access to all resources
  admin_users = [
    "admin1@example.com", 
    "admin2@example.com", 
    "admin3@example.com", 
  ]

  # New accounts to create with read-only permissions
  read_only_users = [
    "user1@example.com",
    "user2@example.com",
    "user3@example.com",
  ]

  # Tags will be added to strongDM and AWS resources.
  tags = {}
}
```

* You can add a prefix (near the top) to the AWS resources, or add tags (at the bottom).
* You may choose not to provision any of the resources listed by simply altering them to "false" (so for example, if you don't want EKS, you change the value from true to false: `create_eks = false`). In order to successfully test, you will need at least one or more resources and the strongDM gateways.
* You may also create strongDM users in various roles, who will be automatically granted access to anything their role would grant them access to.
* If the user(s) specified in the existing users array already have roles assigned to them, this will cause an error. You may remove those users temporarily from their other role, or create new users instead to use in the Terraform script.

> **Note:** If you are using G Suite for an email provider, you may also create additional users without the additional mailboxes quickly and easily by adding `+something` to the end of the username in the email address. Google will ignore this and deliver the mail to the same inbox, allowing you to create aliases for various purposes while still recieiving the mail in one place. So, to create several sample users, you could just make `yourusername+user1@example.com`, `yourusername+user2@example.com`, and `yourusername+user3@example.com`.

## Run the script

1. Open your terminal, navigate to the project directory where your `.tf` files live, and run `terraform init`. This will initialize the Terraform project using your `main.tf` file configuration.

1. Next, run `terraform plan`. This will create an execution plan for your project, and flag any obvious errors or problems before any resources are actually created. You can read through the output of the plan step in order to better understand what Terraform is doing. After entering the `terraform plan` command, you will have to paste in the two credentials items for your AWS key, as well as the two for your strongDM key, in order for the command to execute correctly.

1. Run the `terraform apply` command. This triggers the same thing as the `terrform plan`, including re-entering the keys. The difference is that instead of an output of what would have been created, `terraform apply` will actually perform the acctions. You will have to confirm one time prior to the script executing. The script will take some amount of time, depending on how much you are provisioning, but in the ballpark of 10-30m.

1. Once the script completes, if there are no errors, you will see the success message that summarizes what Terraform did. Head over to your [AWS EC2](https://console.aws.amazon.com/ec2/v2/home), then click **Running Instances** in your region to see the EC2 instances list. Here you should see the new instances that were created, and be able to visually ensure that they are all green and good to go.

1. Head to your strongDM Admin UI and do the same. The script created server(s), datasource(s), gateway(s), website resource(s), and user(s). Take a quick look around, verify that those are all there, and reporting green and good.

## Test it out

We have a working strongDM setup now, so let's get the client installed and test our connection and ability to query our resources!

1. **Install the client GUI if you have not done so** ([macOS](https://www.strongdm.com/docs/user-guide/mac-installation/), [Linux](https://www.strongdm.com/docs/user-guide/linux-installation/)). This is a lightweight program that runs locally on your workstation which will allow you to reach out to your gateway(s), and then through that to whatever resources your user is able to access. Once it is installed, check the toolbar widget to login and see what resources you are being given access to. Alternatively, you can go to the CLI and run `sdm login` to log in, and then, once successfully authenticated, you can run `sdm status` to see what resources are available and their current situation. 

1. **Test a website resource (if you chose to provision one).** Before you test a website resource, you will need to [install a proxy](https://www.strongdm.com/docs/user-guide/http-connection/) which will route requests to strongDM protected resources to sdm before the browser. Once that is done, simply click the website in the GUI in order to connect and load it securely in your browser.

1. **Test a server resource (if you chose to provision one).** To login to a server through sdm is incredibly easy. Click the asset in the GUI widget to activate the connection (or use `sdm connect resourcename`). Then, in your terminal, ssh with the following: `ssh localhost:port` using the port provided by sdm in the GUI. It's that simple. Execute some harmless commands to track later in the logs and replays.

1. **Test a database resource (if you chose to provision one).** First, you'll need to set up whatever database client you use, whether that be a GUI client or the command line. The [Connect to Databases](https://www.strongdm.com/docs/user-guide/db-connection-matrix/) documentation provides you with the settings preferred by each GUI as well as some CLI instructions. Many GUIs, for example, use `localhost` while others prefer `127.0.0.1`. Once you've got your preferred client set up, go ahead and connect to your database! Run a few harmless queries, again, for later viewing.

1. **Look at roles and users screens.** Let's take a quick look at the Admin UI again. In the [Users](https://app.strongdm.com/app/admin) area, you can see the users you created with this script. If you click into each, you'll be able to tab through the various resources, assigning and removing various ones, as well as change the user's role. If you accept the email invite sent to any of these test users and set up a password, you'll be able to experiment with the permissions system, and see how when permission is removed for a resource, sdm instantly deconstructs the tunnel it was using, stopping the user from continuing even in their current session with that resource. 

1. **Logs and Replays.** Finally, you may wish to browse the **Queries** and the **Replays > SSH** tabs, to review the actions you took previously when testing resources. You can see that the logging here is excellent, with every query noted, and replays of sessions are even available for some resources, such as SSH.

## Conclusion

Feel free to test as much as you need, create additional resources, etc. If you have any questions at all, contact our support team at [support@strongdm.com](mailto:support@strongdm.com). Once you are finished testing in your playground, remember to run `terraform destroy` from your project directory and have Terraform deprovision the AWS assets it created, as well as remove the strongDM assets from the Admin UI. This will clean up after your testing as well as ensure that the test assets don't accumulate unwanted costs while sitting unused.
