# TERRAFORM

This project contains examples of how to deploy F5 services with terraform. 

This project attempts to achieve some of the best practices described in links [below](#reference-links) as well as heavily borrows from their examples. 

ex.
creating reusable modules / seperate repos

 - one for infrastructure (blue prints) -> ex. "modules" directory
 - one for live deployments (houses) -> ex. "reference" directory


## REQUIREMENTS

The following are general prerequisites for these templates:
 - Credentials in each environment with the appropriate permission to create associated resources. The list is too exhaustive to list but generally admin privledges are often needed.  
    * Special Note for BIG-IP templates with Pool Member Service Discovery feature: 
        * For AWS, the credentials used in the terraform provider must be able to create IAM Instance Profiles.
        * For Azure, you will need an additional set of api keys with read-only permissions for the BIG-IP to use to discover the pool members.  
 - Accepted the EULA for all images used in the marketplace. If you have not deployed these images in environment before, search for the images in the Marketplace and then click **Accept Software Terms**.  This typically only appears the first time you attempt to launch an image. 
    * Images used:
        - **F5 Best** 
            - **aws**:
                - *util*: https://aws.amazon.com/marketplace/pp/B00JL3Q1HI
                - *byol*: https://aws.amazon.com/marketplace/pp/B00KXHNAPW?ref_=dtl_cpl_B00KXHNAPW_4
            - **azure**:
                - *util*: https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-big-ip-hourly?tab=Overview
                - *byol*: https://azuremarketplace.microsoft.com/en-us/marketplace/apps/f5-networks.f5-big-ip?tab=Overview
            - **gce**: 
                - *byol*: https://console.cloud.google.com/launcher/details/f5-7626-networks-public/f5-big-ip-adc-best-byol?project=f5-5616-pmteam-beta&organizationId=211211374079
        - **Ubuntu 16.04**
            - **aws**: https://aws.amazon.com/marketplace/pp/B01JBL2M0O
            - **azure**: https://azuremarketplace.microsoft.com/en-us/marketplace/apps/Canonical.UbuntuServer?tab=Overview
            - **gce**: https://console.cloud.google.com/launcher/details/ubuntu-os-cloud/ubuntu-xenial?filter=category:os&q=ubuntu&project=f5-5616-pmteam-beta&organizationId=211211374079
 - Key pair for SSH access to instances
    - **aws**: you can create or import the key pair in AWS, see http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html for information.
 - For an admin_password, there are a number of special characters that you should avoid using. See
    - https://support.f5.com/csp/article/K2873 
    - https://docs.microsoft.com/en-us/azure/virtual-machines/windows/faq
    for details.
  Additionally, as we leverage some shell scripts, must also not contain a few bash special character "$" or spaces.

## USAGE

The most challenging part will be obtaining the necessary credentials for each provider. The templates rely on environmental variables for the provider credentials. See the individual provider for each environment for more details. 

https://www.terraform.io/docs/providers/openstack/index.html
https://www.terraform.io/docs/providers/aws/index.html
https://www.terraform.io/docs/providers/azurerm/index.html
https://www.terraform.io/docs/providers/google/index.html

For example, if manually setting environment variables, the file can look like:


```
> cat my-terraform-provider-creds 
#!/bin/bash

# OPENSTACK CREDENTIALS
export OS_AUTH_URL=http://openstack-controller.example.com:5000/v3
export OS_PROJECT_ID=d30gdec30a319d422097e5adasdfsdfsdf
export OS_PROJECT_NAME="my-project"
export OS_USER_DOMAIN_NAME="default"
export OS_USERNAME="user"
export OS_PASSWORD=XXXXXXXXXXXXX
export OS_REGION_NAME="SEA01"

# AWS CREDENTIALS
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_DEFAULT_REGION="us-west-2"

# AZURE CREDENTIALS
export ARM_SUBSCRIPTION_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export ARM_TENANT_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export ARM_CLIENT_ID="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export ARM_CLIENT_SECRET="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"


# GCE CREDENTIALS
export GOOGLE_CREDENTIALS='{
  "type": "service_account",
  "project_id": "my-project",
  "private_key_id": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "private_key": "-----BEGIN PRIVATE KEY-----XXXXXXXXXXXXXXXXXXXXXXXXX-----END PRIVATE KEY-----\n",
  "client_email": "user@my-project.iam.gserviceaccount.com",
  "client_id": "XXXXXXXXXXXXXXXXXXX",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/my-project.iam.gserviceaccount.com"
}'

export GOOGLE_PROJECT="my-project"
export GOOGLE_REGION="us-west1"
```


then before you start, simply run:

```
> source my-terraform-provider-creds
```

Next, as most of the examples leverage modules ( reusable templates ), you must first import or "get" them.

- terraform get
  - In many cases, the modules reference a remote link as the source so internet connectivity will be required.
  - **hint**: use "terraform get -update=true" to make sure your modules are up-to-date

- terraform plan

- terraform apply 

- terraform destroy 


For more information using terraform, please see:

[Terraform](https://www.terraform.io/)

[Getting Started](https://www.terraform.io/intro/getting-started/install.html)


### QUICK START

```
source my-terraform-creds # see above
cd reference/[dir]
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars      # configure any variables required
terraform get
terraform apply

```

### REFERENCE LINKS

 - https://github.com/hashicorp/best-practices/tree/master/terraform/modules/
 - https://www.contino.io/insights/terraform-cloud-made-easy-part-one
 - https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d
 - https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9
 - https://blog.threatstack.com/incorporating-aws-security-best-practices-into-terraform-design

In addition, the folks at dealer.com have also created a BIG-IP provider worth checking out!

 - https://github.com/DealerDotCom/terraform-provider-bigip


### TESTING NOTES

Tested with Terraform v0.9.8

#### ISSUES/WORKAROUNDS:
  
A list of known issues encountered / workarounds incorporated into the templates. They can generally be categorized into following:

- Eventual Consistency related:
    * https://github.com/hashicorp/terraform/issues/2499 - AWS: Certificate not found even though it was just created  ( local-exec )
    * https://github.com/hashicorp/terraform/issues/14970 - API not ready when Terraform completes executing

- Dependency/Ordering:
    * https://github.com/hashicorp/terraform/issues/1178 - depends_on
    * https://github.com/hashicorp/terraform/issues/13934 - Build in tollerance for retryable errors with Azure Provisioner
https://github.com/terraform-providers/terraform-provider-azurerm/issues/111 - Destroy doesn't work for azure LB 
    * https://github.com/hashicorp/terraform/issues/6234 - google_compute_instance_group_manager does not get destroyed when google_compute_instance_template does, resulting in error
    * https://github.com/hashicorp/terraform/issues/6678 - 'google_compute_instance' adding 'google_compute_disk' forces new resource 
    * https://github.com/hashicorp/terraform/issues/11905 - provider/google incorrect update order between instance template and group manager 

- Feature Parity:
    * https://github.com/hashicorp/terraform/issues/1552 - aws: Allow rolling updates for ASGs
    * https://github.com/hashicorp/terraform/issues/12889 - Include auto scale settings for Azure VM scale sets


