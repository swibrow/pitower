variable "tags" {
  type = map(string)
  default = {
    GithubRepo = "pitower"
    GithubOrg  = "swibrow"
  }
}

variable "subjects" {
  description = "The list of subjects that will be allowed to assume the role"
  type        = list(string)
  default = [
    "swibrow/pitower:pull_request",
    "swibrow/pitower:ref:refs/heads/main",
    # "repo:swibrow/actions-playground:*",
  ]
}
