> [!Warning]
> This architecture is presented only as an example. Additional configuration may be required based on your needs and security requirements

## Architecture Overview
### Ansible & Packer
Packer is used to generate an AMI which can be used by EC2 instances.
The configuration of this AMI is done through Anisble. There are several roles that are used by the playbook to configure a basic PHP webserver. The roles configure Nginx and PHP-fpm as well as several security defaults.
Ansible variables control the logic of the roles. An example of these settings can be found in `/ansible/php-webserver/vars.yaml`his

