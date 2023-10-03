provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
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

resource "kubernetes_cluster_role" "role" {
  metadata {
    name = "tf-role"
  }
  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources = ["customresourcedefinitions"]
    verbs = ["list"]
  }
}

resource "kubernetes_cluster_role_binding" "rolebinding" {
  metadata {
    name = "tf-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "ClusterRole"
    name = "tf-role"
  }

  subject {
    kind = "User"
    name = "system:serviceaccount:flux-system:tf-runner"
    api_group = "rbac.authorization.k8s.io"
  }
}
