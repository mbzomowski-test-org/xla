provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  cluster_ca_certificate = google_container_cluster.primary.master_auth.0.cluster_ca_certificate
  load_config_file = "false"
  client_certificate     = google_container_cluster.primary.master_auth.0.client_certificate
  client_key             = google_container_cluster.primary.master_auth.0.client_key
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
