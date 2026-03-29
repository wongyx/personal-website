# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
 url             = "https://token.actions.githubusercontent.com"
 client_id_list  = ["sts.amazonaws.com"]
 thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
 name = "github-actions-role"
  assume_role_policy = jsonencode({
   Version = "2012-10-17"
   Statement = [
     {
       Effect = "Allow"
       Action = "sts:AssumeRoleWithWebIdentity"
       Principal = {
         Federated = aws_iam_openid_connect_provider.github.arn
       }
       Condition = {
         StringEquals = {
           "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
         }
         StringLike = {
           "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_name}:*"
         }
       }
     }
   ]
 })
}

# Attach policies to the role
resource "aws_iam_role_policy_attachment" "github_actions_policy" {
 role       = aws_iam_role.github_actions.name
 policy_arn = aws_iam_policy.github_actions.arn
}

resource "aws_iam_policy" "github_actions" {
    name = "github-actions-deploy-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = var.cloudfront_distribution_arn
      }
    ]
  })
}