variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_owner" { type = string }   # e.g. raphewkarimissah
variable "github_repo"  { type = string }   # e.g. my-repo
variable "github_branch" {
  type    = string
  default = "master"
}

