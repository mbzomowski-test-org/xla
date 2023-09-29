provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

resource "kubernetes_manifest" "flux-repo" {
  manifest = {
    "apiVersion" = "source.toolkit.fluxcd.io/v1"
    "kind" = "GitRepository"
    "metadata" = {
      "name" = "source-repo"
      "namespace" = var.flux_namespace
    }
    "spec" = {
      "interval" = "30s"
      "url" = "https://github.com/mbzomowski/xla"
      "ref" = {
        "branch" = "master"
      }
      "ignore" = "secret.tf"
    }
  }

  depends_on = [
    helm_release.tf-controller
  ]
}

resource "kubernetes_manifest" "flux-terraform" {
  manifest = {
    "apiVersion" = "infra.contrib.fluxcd.io/v1alpha2"
    "kind" = "Terraform"
    "metadata" = {
      "name" = "tf-object"
      "namespace" = var.flux_namespace
    }
    "spec" = {
      "approvePlan" = "auto"
      "path" = "./tpu-ci/"
      "interval" = "1m"
      "sourceRef" = {
        "kind" = "GitRepository"
        "name" = "source-repo"
        "namespace" = var.flux_namespace
      }
    }
  }
  depends_on = [
    helm_release.tf-controller
  ]
}
