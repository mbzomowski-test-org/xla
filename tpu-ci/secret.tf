variable "GITHUB_TOKEN" {
  type = string
}

resource "kubernetes_secret" "github-pat" {
  metadata {
    name = "github-pat"
    namespace = var.runner_namespace
  }
  depends_on = [
    helm_release.arc-runner-set
  ]

  data = {
    github_token = var.GITHUB_TOKEN
  }
}
