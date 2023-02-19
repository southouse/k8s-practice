output "app_security_groups_id" {
  description = "The ID of the security group"
  value       = { for p in sort(keys(local.ingress_security_groups)) : p => module.app_security_groups[p].security_group_id}
}

output "eks_cluster_sg_id" {
  description = "The ID of the security group"
  value       = module.eks_cluster_sg.security_group_id
}

output "eks_cluster_control_plain_sg_id" {
  description = "The ID of the security group"
  value       = module.eks_cluster_control_plain_sg.security_group_id
}

output "eks_cluster_node_sg_id" {
  description = "The ID of the security group"
  value       = module.eks_cluster_node_sg.security_group_id
}