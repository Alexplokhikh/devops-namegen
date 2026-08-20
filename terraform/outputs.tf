output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "github_actions_role_arn" {
  value = module.cicd.role_arn
}

output "load_balancer_hostname" {
  value = try(kubernetes_service_v1.namegen.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "grafana_admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}
