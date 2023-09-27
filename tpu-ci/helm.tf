variable "arc_namespace" {
  default = "arc-systems"
  description = "the namespace in which the ARC controller will reside"
}

variable "runner_namespace" {
  default = "arc-runners"
  description = "the namespace in which the ARC runners will reside"
}

variable "flux_namespace" {
  default = "flux-system"
  description = "the namespace in which the flux resources will reside"
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

resource "helm_release" "arc" {
    name = "actions-runner-controller"
    chart = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller"
    namespace = var.arc_namespace
    create_namespace = true
}

resource "helm_release" "arc-runner-set" {
  name = "runner-set"
  depends_on = [
    helm_release.arc
  ]
  chart = "oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set"
  namespace = var.runner_namespace
  create_namespace = true

  values = [
    "${file("arc-values.yaml")}"
  ]
}

resource "helm_release" "flux" {
  name = "flux"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart = "flux2"
  namespace = "flux-system"
  create_namespace = true
}

resource "helm_release" "tf-controller" {
  name = "tf-controller"
  repository = "https://weaveworks.github.io/tf-controller/"
  chart = "tf-controller"
  namespace = var.flux_namespace
  depends_on = [
    helm_release.flux
  ]
  values = [
    "${file("tf-controller-values.yaml")}"
  ]
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
        "name" = "flux-repo"
        "namespace" = var.flux_namespace
      }
    }
  }
  depends_on = [
    helm_release.tf-controller
  ]
}
