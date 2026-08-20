variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type    = string
  default = "devops-namegen"
}

variable "cluster_name" {
  type    = string
  default = "devops-namegen-eks"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34"
}

variable "github_username" {
  type    = string
  default = "Alexplokhikh"
}

variable "github_owner_id" {
  type    = string
  default = "126824464"
}

variable "github_repository_name" {
  type    = string
  default = "devops-namegen"
}

variable "github_repository_id" {
  description = "Numeric GitHub repository ID. Create the repo first, then retrieve it from the GitHub API."
  type        = string
}

variable "mongo_app_user" {
  type    = string
  default = "genuser"
}

variable "mongo_app_password" {
  type      = string
  sensitive = true
  default   = "password"
}

variable "mongo_root_user" {
  type    = string
  default = "rootadmin"
}

variable "mongo_root_password" {
  type      = string
  sensitive = true
  default   = "namegen-root-password"
}

variable "namegen_image_tag" {
  description = "Initial image tag already present in ECR before the Kubernetes workload is created."
  type        = string
  default     = "bootstrap"
}
