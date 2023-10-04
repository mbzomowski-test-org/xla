data "google_client_config" "provider" {}

data "google_container_cluster" "primary" {
  name = "bzmarke-tpu-cluster"
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token = data.google_client_config.provider.access_token
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
      "serviceAccountName" = google_service_account.gsa.name
      "runnerPodTemplate" = {
        "spec" = {
          "nodeSelector" = {
            "iam.gke.io/gke-metadata-server-enabled" = "true"
          }
        }
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

resource "kubernetes_service_account" "ksa" {
  metadata {
    name = "tf-ksa"
    namespace = var.flux_namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = "${google_service_account.gsa.account_id}@${var.project_id}.iam.gserviceaccount.com"
    }
  }
}


