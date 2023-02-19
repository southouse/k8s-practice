output "ec2_instances_id" {
  value       = { for p in sort(keys(local.ec2_instances)) : p => module.ec2_instance[p].id}
}

output "ec2_instances_public_ip" {
  value       = { for p in sort(keys(local.ec2_instances)) : p => module.ec2_instance[p].public_ip}
}

output "ec2_instances_private_ip" {
  value       = { for p in sort(keys(local.ec2_instances)) : p => module.ec2_instance[p].private_ip}
}

output "public_key_pem" {
  value       = module.key_pair.public_key_pem
}