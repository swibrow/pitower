data "tls_certificate" "kubernetes_oidc" {
  url = "https://raw.githubusercontent.com/swibrow/pitower/main/kubernetes/pitower"
}

resource "aws_iam_openid_connect_provider" "kubernetes_oidc" {
  url             = "https://raw.githubusercontent.com/swibrow/pitower/main/kubernetes/pitower"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.kubernetes_oidc.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "pitower_test" {
  name = "pitower"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : [
            aws_iam_openid_connect_provider.kubernetes_oidc.arn
          ]
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${aws_iam_openid_connect_provider.kubernetes_oidc.url}:sub" : "system:serviceaccount:test:pitower-test",
            "${aws_iam_openid_connect_provider.kubernetes_oidc.url}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  inline_policy {
    name = "pitower-test"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "s3:ListAllMyBuckets"
          ],
          "Resource" : "*"
        }
      ]
    })
  }
}
