resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.github_oidc_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}@${var.github_owner_id}/${var.github_repository_name}@${var.github_repository_id}:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "ecr" {
  name = "${var.project_name}-github-actions-ecr"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = var.ecr_repository_arn
      }
    ]
  })
}

resource "aws_iam_policy" "eks" {
  name = "${var.project_name}-github-actions-eks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = var.cluster_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr.arn
}

resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.eks.arn
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["default"]
  }

  depends_on = [aws_eks_access_entry.github_actions]
}
