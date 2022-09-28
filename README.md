# Quick Start strongDM with Terraform and AWS

This Terraform module gets you up and running with strongDM quickly by automating the creation of a variety of users, resources, and gateways. Keep reading to get hands-on experience and test strongDM's capabilities when integrating with Amazon Web Services (AWS).

## Prerequisites

To successfully run the AWS Terraform module, you need the following:

- A strongDM administrator account. If you do not have one, [sign up](https://www.strongdm.com/signup-contact/) for a trial.
- A [strongDM API key](https://www.strongdm.com/docs/admin-ui-guide/access/api-keys/), which can be generated in the [strongDM Admin UI](https://app.strongdm.com/app/access/tokens). Your strongDM API key needs all permissions granted to it in order to generate the users and resources for these Terraform scripts.
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) v0.14.0 or higher installed on your computer.
- An AWS account and an AWS API key with permissions to provision all intended AWS resources. To control these settings, go to your [AWS Dashboard](https://console.aws.amazon.com/ec2/v2/home) and click **Key Pairs**.

> **Warning:** These scripts create infrastructure resources in your AWS account, incurring AWS costs. Once you are done testing, remove these resources to prevent unnecessary AWS costs. You can remove resources manually or with `terraform destroy`. strongDM provides these scripts as is, and does not accept liability for any alterations to AWS assets or any AWS costs incurred.

## Run the Terraform Module

To work with the examples in this repository, follow these directions.

1. Clone the repository:

    ```shell
    git clone https://github.com/strongdm/terraform-sdm-onboarding.git
    ```

2. Switch to the directory containing the cloned project:

    ```shell
    cd terraform-sdm-onboarding
    ```

3. Initialize the working directory containing the Terraform configuration files:

    ```shell
    terraform init
    ```

4. Execute the actions proposed in the Terraform plan:

    ```shell
    terraform apply
    ```

5. The script asks you for the following values. If you prefer not to enter these values each time you run the module, you can store them in the `variables.tf` file found in the root of the project.

    - Your AWS access key ID and secret
    - Your AWS region
    - Your strongDM API key ID and secret
    - Your strongDM administrator email

    Once you add these values, the script runs until it is complete. Note any errors. If there are no errors, you should see new resources, such as gateways, databases, or servers, in the strongDM Admin UI. Additionally, your AWS Management Console displays any new EC2 instances added when you ran the module.

6. If necessary, remove the resources created with your Terraform plan:

    ```shell
    terraform destroy
    ```

## Customize the Terraform Module

You can optionally modify the `onboarding.tf` file to meet your needs, including altering the resource prefix, or spinning up additional resources which are commented out in the script.

To give you an idea of the script's total run time, estimates are provided to indicate the time it may take to spin up each resource after Terraform triggers it. Additionally, there are a few other items to consider in relation to the `onboarding.tf` file:

- You can add resource tags at the bottom of the file.
- You may choose not to provision any of the resources listed by commenting them out in the script, or altering their value to `false`. In order to successfully test, you need to keep at least one or more resource(s) and the strongDM gateways.

## Conclusion

Feel free to create additional resources and to test as much as needed. If you have any questions, contact our support team at [support@strongdm.com](mailto:support@strongdm.com).

Once you are finished testing, remember to run `terraform destroy` from your project directory. With this command, Terraform deprovisions the AWS assets it created and it also removes the strongDM assets from the Admin UI. This clean ups after your testing and ensures that test assets do not accumulate unwanted costs while sitting unused.
