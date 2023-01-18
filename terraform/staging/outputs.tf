output "ad_management_server_private_ip" {
  value = module.active_directory.ad_management_server_private_ip
}

output "ad_management_server_password" {
  value     = module.active_directory.ad_management_server_password
  sensitive = true
}

output "ad_ca_server_private_key" {
  value     = module.active_directory.ca_server_private_key
  sensitive = true
}

output "directory_admin_password" {
  value     = module.active_directory.directory_admin_password
  sensitive = true
}

output "ad_dns_servers" {
  value = module.active_directory.dns_servers
}

output "ml_hostname" {
  value = module.marklogic.ml_hostname
}

output "ml_ssh_private_key" {
  value     = module.marklogic.ml_ssh_private_key
  sensitive = true
}

output "bastion_host_key_fingerprint" {
  value = module.bastion.bastion_host_key_fingerprint_sha256
}

output "bastion_dns_name" {
  value = module.bastion.bastion_dns_name
}

output "bastion_ssh_keys_bucket" {
  value = module.bastion.ssh_keys_bucket
}

output "bastion_ssh_private_key" {
  value     = tls_private_key.bastion_ssh_key.private_key_openssh
  sensitive = true
}

output "bastion_sg_id" {
  value = module.bastion.bastion_security_group_id
}

output "delta_internal_subnet_ids" {
  value = module.networking.delta_internal_subnets[*].id
}

output "delta_api_subnet_ids" {
  value = module.networking.delta_api_subnets[*].id
}

output "delta_website_subnet_ids" {
  value = module.networking.delta_website_subnets[*].id
}

output "public_subnet_ids" {
  value = module.networking.public_subnets[*].id
}

output "vpc_id" {
  value = module.networking.vpc.id
}

output "cpm_private_subnet_ids" {
  value = module.networking.cpm_private_subnets[*].id
}

output "keycloak_private_subnet_ids" {
  value = module.networking.keycloak_private_subnets[*].id
}

output "gh_runner_private_key" {
  value     = module.gh_runner.private_key
  sensitive = true
}

output "private_dns" {
  value = module.networking.private_dns
}

output "jaspersoft_alb_domain" {
  value = module.public_albs.jaspersoft.dns_name
}

output "jaspersoft_private_ip" {
  value = module.jaspersoft.instance_private_ip
}

output "jaspersoft_ssh_private_key" {
  value     = tls_private_key.jaspersoft_ssh_key.private_key_openssh
  sensitive = true
}

output "required_dns_records" {
  value = [for record in local.all_dns_records : record if !endswith(record.record_name, "${var.secondary_domain}.")]
}

output "public_albs" {
  value = {
    delta      = module.public_albs.delta
    api        = module.public_albs.delta_api
    keycloak   = module.public_albs.keycloak
    cpm        = module.public_albs.cpm
    jaspersoft = module.public_albs.jaspersoft
  }
  # Includes CloudFront keys
  sensitive = true
}

output "session_manager_policy_arn" {
  value = module.session_manager_config.policy_arn
}

output "ml_http_target_group" {
  value = module.marklogic.ml_http_target_group
}
