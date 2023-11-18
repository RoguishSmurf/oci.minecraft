# Minecraft Project

1. Install and configure OCI-CLI
1. Configure the Terraform provider to use OCI-CLI/Cloud Shell.
    * `config.s3.tfbackend`
1. Run `create_bucket.sh` to create state bucket for Terraform
1. Run `create_vault_and_secret.sh <password>` to store the Ansible Vault password.
1. Build the project
    * `terraform apply`

1. Run the Ansible playbooks to configure servers