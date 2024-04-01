variable "tags" {
  type = map(string)
  default = {
    GithubRepo = "pitower"
    GithubOrg  = "swibrow"
  }
}
