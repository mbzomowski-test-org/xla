provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
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
    github_token = "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"
  }
}
