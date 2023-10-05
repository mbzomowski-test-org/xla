provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

resource "helm_release" "cert-manager" {
  name  = "cert-manager"
  chart = "cert-manager"
  repository = "oci://registry-1.docker.io/bitnamicharts"

  depends_on = [
    google_container_node_pool.primary_nodes
  ]

  values = [
    "${file("cm-values.yaml")}"
  ]
}

resource "helm_release" "actions-runner-controller" {
    name = "actions-runner-controller"
    chart = "actions-runner-controller"
    repository = "https://actions-runner-controller.github.io/actions-runner-controller"

    depends_on = [
      helm_release.cert-manager
    ]

    values = [
      "${file("arc-values.yaml")}"
    ]
}
