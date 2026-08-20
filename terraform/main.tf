module "network" {
  source       = "./modules/network"
  project_name = var.project_name
}

module "ecr" {
  source          = "./modules/ecr"
  repository_name = var.project_name
}

module "eks" {
  source             = "./modules/eks"
  project_name       = var.project_name
  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version
  subnet_ids         = module.network.public_subnet_ids
}

module "cicd" {
  source = "./modules/cicd"

  project_name           = var.project_name
  aws_region             = var.aws_region
  github_oidc_arn        = data.aws_iam_openid_connect_provider.github.arn
  github_username        = var.github_username
  github_owner_id        = var.github_owner_id
  github_repository_name = var.github_repository_name
  github_repository_id   = var.github_repository_id

  ecr_repository_arn = module.ecr.repository_arn
  cluster_name       = module.eks.cluster_name
  cluster_arn        = module.eks.cluster_arn
}
