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

| Security Group | Associated Resources | Inbount Rules | Outbound Rules |
| -------------- | -------------------- | ------------- | -------------- |
| Load Balancer  | Load Balancer        | `Port 443 from Cloudfront`| `Port 80 to Webserver SG` |
| Webserver      | Webserver EC2 Instances | `Port 80 from Load Balancer SG` | `Port 80 to VPC Endpoint SG` <br> `Port 443 to VPC Endpoint SG` <br> `Port 80 to S3 Prefix List` <br> `Port 443 to S3 Prefix List` <br> `Port 3306 to RDS SG` <br> `Port 6379 to Redis SG` |
| VPC Endpoints  | All non-S3 VPC Endpoints | `Port 80 from Webserver SG` <br> `Port 443 from Webserver SG` | `None` |
| RDS            | RDS Cluster          | `Port 3306 from Webserver SG` | `None` |
| Redis          | Elasticache Redis Cluster | `Port 6379 from Webserver SG` | `None` |
