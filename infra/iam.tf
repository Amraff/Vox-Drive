# ECS task role (used by running container) -> allow Polly + S3 if needed
resource "aws_iam_role" "ecs_task_role" {
  name = "audiobook-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "polly" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPollyFullAccess"
}
# Execution role to allow ECS to pull images and write logs
resource "aws_iam_role" "ecs_exec_role" {
  name = "audiobook-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_exec_assume.json
}
data "aws_iam_policy_document" "ecs_exec_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "exec_ecr" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# GitHub OIDC provider (so GitHub Actions can assume an AWS role)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"] # GitHub thumbprint (common)
}

# Role for GitHub Actions to assume via OIDC
data "aws_iam_policy_document" "github_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-oidc-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}
# Attach limited policies the CI needs: ECR push, ECS update, CloudWatch logs
resource "aws_iam_role_policy_attachment" "ci_ecr" {
  role = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}
resource "aws_iam_role_policy_attachment" "ci_ecs" {
  role = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}
resource "aws_iam_role_policy_attachment" "ci_logs" {
  role = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_actions_role.arn
}
