# Quick Start StrongDM with Terraform and AWS

This Terraform module gets you up and running with StrongDM quickly by automating the creation of a variety of users, resources, and gateways. Keep reading to get hands-on experience and test StrongDM's capabilities when integrating with Amazon Web Services (AWS).

## Prerequisites

To successfully run the AWS Terraform module, you need the following:

- A StrongDM administrator account. If you do not have one, [sign up](https://www.strongdm.com/signup-contact/) for a trial.
- A [StrongDM API key](https://www.strongdm.com/docs/admin-ui-guide/access/api-keys/), which you can generate in the [StrongDM Admin UI](https://app.strongdm.com/app/access/tokens). Your StrongDM API key needs all permissions granted to it in order to generate the users and resources for these Terraform scripts.
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) v0.14.0 or higher installed on your computer.
- An AWS account and an AWS API key with permissions to provision all intended AWS resources. To control these settings, go to your [AWS Dashboard](https://console.aws.amazon.com/ec2/v2/home) and click **Key Pairs**.

> **Warning:** These scripts create infrastructure resources in your AWS account, incurring AWS costs. Once you are done testing, remove these resources to prevent unnecessary AWS costs. You can remove resources manually or with `terraform destroy`. StrongDM provides these scripts as is, and does not accept liability for any alterations to AWS assets or any AWS costs incurred.

## Run the Terraform Module

Our [public GitHub repository](https://github.com/strongdm/terraform-sdm-onboarding) stores code examples for your Terraform onboarding quick start with AWS. To work with the examples in our repository, follow these directions.

1. Clone the repository:

    ```shell
    git clone https://github.com/strongdm/terraform-sdm-onboarding.git
    ```

2. Switch to the directory containing the cloned project:

    ```shell
    cd terraform-sdm-onboarding
    ```

3. Set environment variables for the API key

    ```shell
    # strongdm access and secret keys
    export SDM_API_ACCESS_KEY=auth-xxxxxxxxxxxx
    export SDM_API_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    # For the AWS creds, ideally set your profile.
    export AWS_PROFILE=sandbox-admin

    # Otherwise, set your keys
    # export AWS_ACCESS_KEY_ID=xxxxxxxxx
    # export AWS_SECRET_ACCESS_KEY=xxxxxxxxx
    ```

    Note that [direnv](https://direnv.net) is a secure solution to automatically load environment variables from a `.envrc` file as soon as you are in the directory containing the file.

4. Initialize the working directory containing the Terraform configuration files:

    ```shell
    terraform init
    ```

5. Execute the actions proposed in the Terraform plan:

    ```shell
    terraform apply
    ```

    The script runs until it is complete. Note any errors. If there are no errors, you should see new resources, such as gateways, databases, or servers, in the StrongDM Admin UI. Additionally, your AWS Management Console displays any new EC2 instances added when you ran the module.

6. If necessary, remove the resources created with your Terraform plan:

    ```shell
    terraform destroy
    ```

## Customize the Terraform Module

You can optionally modify the `onboarding.tf` file to meet your needs, including altering the resource prefix, or spinning up additional resources that are commented out in the script.

To give you an idea of the script's total run time, the file provides estimates to indicate the time it may take to spin up each resource after Terraform triggers it. Additionally, there are a few other items to consider in relation to the `onboarding.tf` file:

- You can add resource tags at the bottom of the file.
- You may choose not to provision any of the resources listed by commenting them out in the script or by altering their value to `false`. In order to successfully test, you need to keep at least one resource and one StrongDM gateway.

## Conclusion

Feel free to create additional resources and to test as much as needed. If you have any questions, contact our Support team at <support@strongdm.com>.

Once you are finished testing, remember to run `terraform destroy` from your project directory. With this command, Terraform deprovisions the AWS assets it created and it also removes the StrongDM assets from the Admin UI. This cleans up after your testing and ensures that test assets do not accumulate unwanted costs while sitting unused.
