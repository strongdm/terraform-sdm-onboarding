# Quick Start strongDM with Terraform

This Terraform module gets you up and running with strongDM quickly, with a variety of users, resources, and gateways to help you to more quickly get hands-on experience and test out strongDM's capabilities.

## Prerequisites

* A strongDM account (if you don't have one, [sign up here](https://www.strongdm.com/signup-contact/)) and a strongDM API key, which can be generated in the <a href="https://app.strongdm.com/app/settings" target="_blank">strongDM Admin UI</a>. Your strongDM API key will need all permissions granted to it in order to generate the users and resources for this script.
* [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) v0.14.0 or higher installed on your computer.
* An Amazon Web Services (AWS) account and an API key with permissions sufficient to provision all of the resources you intend to provision ([AWS Dashboard](https://console.aws.amazon.com/ec2/v2/home) > Key Pairs).

> **Warning:** The script will create AWS resources on your account, which will incur AWS costs. Once you're done testing, you will likely want to remove them to prevent unnecessary AWS costs, either manually or with `terraform destroy`. strongDM provides this script as is, and does not accept liability for any alterations to AWS assets or any AWS costs incurred.

## Instructions

1. Clone the repository and then enter the directory
    ```
    git clone https://github.com/strongdm/terraform-sdm-onboarding.git
    cd terraform-sdm-onboarding
    ```
2. Initialize the Terraform directory, and then if all goes well, start the script.
    ```
    terraform init
    terraform apply
    ```
3. The script will ask you for a total of six values: Your AWS access key ID and secret, your AWS region, your strongDM API key ID and secret, and your strongDM administrator email, who will be added to the newly created role in strongDM. Once these are filled in, the script will run for a few minutes, and then complete. Take note of any errors. If there are none, you should be able to see the new servers and databases available in the strongDM Admin UI, and should be able to look at your AWS Management Console and see the new EC2 instances.

## Optional - Customize the Terraform module

If you wish, you can modify the `onboarding.tf` to meet your needs, including altering the resource prefix, or spinning up additional resources which are currently commented out in the script. Rough time estimates are provided in the script for how long it might take on average to spin up that resource after Terraform triggers it, giving you an idea of the script's total run time. Additionally, there are a few other items to consider:

* You can add tags (at the bottom).
* You may choose not to provision any of the resources listed by simply commenting them out in the script, or altering their value to "false". In order to successfully test, you will need to keep at least one or more resource(s) and the strongDM gateways.
* You may also create strongDM users in various roles who will be automatically granted access to anything their role would grant them access to.
* If the users specified in the existing users array already have roles assigned to them, this will cause an error. You may remove those users temporarily from their other role, or create new users instead to use for the demo.

> **Note:** If you are using G Suite for an email provider, you may also create additional users without needing additional mailboxes quickly and easily by adding `+something` to the end of the username in the email address. Google will ignore this and deliver the mail to the same inbox, allowing you to create aliases for various purposes while still recieiving the mail in one place. So, to create several sample users, you could just make `yourusername+user1@example.com`, `yourusername+user2@example.com`, and `yourusername+user3@example.com`.

## Conclusion

Feel free to test as much as you need, create additional resources, etc. If you have any questions at all, contact our support team at [support@strongdm.com](mailto:support@strongdm.com). Once you are finished testing, remember to run `terraform destroy` from your project directory and have Terraform deprovision the AWS assets it created, as well as remove the strongDM assets from the Admin UI. This will clean up after your testing as well as ensure that the test assets don't accumulate unwanted costs while sitting unused.
