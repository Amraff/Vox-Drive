resource "aws_ecr_repository" "app" {
  name = "fastapi-polly"
  image_tag_mutability = "MUTABLE"
}
output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}