output "iam_github_oidc_role" {
  value = module.iam_github_oidc_role
}

output "pod_identity_role" {
  value = aws_iam_role.pitower_test.arn
}
