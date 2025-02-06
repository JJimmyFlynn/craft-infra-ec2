> [!Warning]
> This architecture is presented only as an example. Additional configuration may be required based on your needs and security requirements

## Architecture Overview
### Ansible & Packer
Packer is used to generate an AMI which can be used by EC2 instances.
The configuration of this AMI is done through Anisble. There are several roles that are used by the playbook to configure a basic PHP webserver. The roles configure Nginx and PHP-fpm as well as several security defaults.
Ansible variables control the logic of the roles. An example of these settings can be found in `/ansible/php-webserver/vars.yaml`his

### VPC
> [!Note]
> This architecture assumes a fresh VPC. In a real life scenario you may want to utilize an existing VPC.

This application's VPC aims to be as private as possible. The application EC2 instances live within a private subnet and utilize NAT gateways and VPC Endpoints to communicate with other AWS services and the internet. 
This architecture provisions VPC Endpoints for the following services:
- S3
- Cloudwatch
- SSM
- SSM Messages

The VPC requires at least 2 AZs. The total number of AZs utilized can be set with the `vpc_az_count` terraform variable

### Load Balancer
An ALB is configured to route traffic to the application EC2 instances target group. As explained in the CloudFront section, this application is frontend by CloudFront and
the ALB only allows incoming connections from the CloudFront Service. The ALB listens on both HTTP and HTTPS but redirects all traffic to HTTPS.
#### Health Checks
The ALB performs a health check by accessing the built-in Craft health check route at `/actions/app/health-check`

### S3
This architecture provisions 2 S3 buckets. One for the application's uploaded assets and one for the build artifact from the CI/CD pipeline

The assets S3 bucket's Bucket Policy is configured to make the bucket accessible only to the CloudFront distribution and to the VPC Endpoint for S3 

### CloudFront
A CloudFront distribution is placed in front of the ALB and therefore all ingress traffic for the application goes through it.

The distribution has two origins: one for the applications assets
(which are stored at a `/assets` path and routed based on that path) which is pointed at the S3 bucket for assets, and one for every other path which is pointed at the ALB.

The ALB only accepts ingress traffic from the CloudFront distribution, ensuring all traffic is subject to CloudFront's protections and caching.

### WAF
The CloudFront distribution is also backed by a Web ACL from AWS WAF. This adds further protection to all ingress traffic to the application.

The Web ACL is configured to use a set of AWS managed rulesets:
- Common Rules
- Known Bad Inputs
- Common SQL
- Common Linux
- Common Unix
- Common PHP
- IP Reputation
- Bot Protection

### EC2
The heart of this infrastructure is EC2. The VMs are deployed with a Launch Template using a custom AMI created by Packer/Ansible.

All instances are deployed within private subnets and utilize VPC enpoints for communication with necessary AWS services.

The instances are deployed in an auto-sacling group which uses a tracking policy to monitor the average CPU utilization and manage the number of instances. 
A clound init sctipt fetches the latest application release artifact from an S3 bucket on instance creation and grabs the environment variables nesessary to run the application from SSM Parameter Store.

### Security Groups

| Security Group | Associated Resources      | Inbount Rules                                                 | Outbound Rules                                                                                                                                                                             |
|----------------|---------------------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Load Balancer  | Load Balancer             | `Port 443 from Cloudfront`                                    | `Port 80 to Webserver SG`                                                                                                                                                                  |
| Webserver      | Webserver EC2 Instances   | `Port 80 from Load Balancer SG`                               | `Port 80 to VPC Endpoint SG` <br> `Port 443 to VPC Endpoint SG` <br> `Port 80 to S3 Prefix List` <br> `Port 443 to S3 Prefix List` <br> `Port 3306 to RDS SG` <br> `Port 6379 to Redis SG` |
| VPC Endpoints  | All non-S3 VPC Endpoints  | `Port 80 from Webserver SG` <br> `Port 443 from Webserver SG` | `None`                                                                                                                                                                                     |
| RDS            | RDS Cluster               | `Port 3306 from Webserver SG`                                 | `None`                                                                                                                                                                                     |
| Redis          | Elasticache Redis Cluster | `Port 6379 from Webserver SG`                                 | `None`                                                                                                                                                                                     |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.84.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.84.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 5.0.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_aurora_instance_count"></a> [aurora\_instance\_count](#input\_aurora\_instance\_count) | The total number of instances to create in the RDS cluster | `number` | `1` | no |
| <a name="input_aurora_max_capacity"></a> [aurora\_max\_capacity](#input\_aurora\_max\_capacity) | The maximum ACUs used in the RDS autoscaling policy. Must be more than `aurora_min_capacity`. Range of 1 - 128 | `number` | `4` | no |
| <a name="input_aurora_min_capacity"></a> [aurora\_min\_capacity](#input\_aurora\_min\_capacity) | The minimum ACUs used in the RDS autoscaling policy. Must be less than `aurora_min_capacity`. Range of 0.5 - 128 | `number` | `1` | no |
| <a name="input_autoscaling_cpu_tracking_target"></a> [autoscaling\_cpu\_tracking\_target](#input\_autoscaling\_cpu\_tracking\_target) | The target average CPU usage of the autoscaling group used in the target tracking autoscaling policy | `number` | `60` | no |
| <a name="input_autoscaling_max_quantity"></a> [autoscaling\_max\_quantity](#input\_autoscaling\_max\_quantity) | Maximum ec2 instances for the autoscaling group | `number` | `3` | no |
| <a name="input_autoscaling_min_quantity"></a> [autoscaling\_min\_quantity](#input\_autoscaling\_min\_quantity) | Minimum ec2 instances for the autoscaling group | `number` | `1` | no |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | n/a | `string` | n/a | yes |
| <a name="input_cloudflare_zone_id"></a> [cloudflare\_zone\_id](#input\_cloudflare\_zone\_id) | n/a | `string` | n/a | yes |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>   format = string<br/>   labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Domain name of the application and ACM cert | `string` | n/a | yes |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_parameter_store_path"></a> [parameter\_store\_path](#input\_parameter\_store\_path) | The path at which ssm parameters are stored for this application/stage. e.g. /example-application/dev | `string` | n/a | yes |
| <a name="input_redis_instance_count"></a> [redis\_instance\_count](#input\_redis\_instance\_count) | n/a | `number` | `1` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | n/a | `string` | `"cache.r7g.large"` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where resource will be created | `string` | n/a | yes |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of the role for terraform to assume | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |
| <a name="input_vpc_az_count"></a> [vpc\_az\_count](#input\_vpc\_az\_count) | The number of private and public subnets to be created. Each will be provisioned into their own AZ | `number` | `2` | no |
<!-- END_TF_DOCS -->    
