output "delete_evicted_pod_pv_id" {
  value = aws_efs_file_system.delete_evicted_pod_pv.id
}

output "delete_evicted_pod_pv_dns_name" {
  value = aws_efs_file_system.delete_evicted_pod_pv.dns_name
}