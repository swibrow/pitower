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
    "swibrow/home-ops:pull_request",
    "swibrow/home-ops:ref:refs/heads/main",
    # "repo:swibrow/actions-playground:*",
  ]
}
