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

resource "kubernetes_secret" "github-pat-flux" {
  metadata {
    name = "github-pat"
    namespace = "flux-system"
  }
  depends_on = [
    helm_release.arc-runner-set
  ]

  data = {
    github_token = var.GITHUB_TOKEN
  }
}

/*
resource "kubernetes_secret" "tf-sa" {
  metadata {
    name = "tf-sa"
    namespace = "flux-system"
  }
  data = {
    
  }
}*/
