output "eks_iam_policy_arn" {
  value = module.eks_iam_policy.arn
}

output "eks_efs_csi_iam_policy_arn" {
  value = module.eks_efs_csi_iam_policy.arn
}

output "iam_role_arn" {
  value       = module.iam_assumable_role.iam_role_arn
}

output "iam_role_name" {
  value       = module.iam_assumable_role.iam_role_name
}

output "iam_instance_profile_id" {
  value       = module.iam_assumable_role.iam_instance_profile_id
}