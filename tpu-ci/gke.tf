# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "project_id" {
  default = "tpu-pytorch"
}

variable "region" {
  default = "us-central2"
}

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "machine_type" {
  default = "ct4p-hightpu-4t"
  description = "tpu machine type"
}

variable "tpu_topology" {
  default = "2x2x1"
  description = "tpu topology"
}

data "google_client_config" "default" {}

# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "bzmarke-tpu-cluster"
  location = var.region
  
  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  release_channel {
    channel = "RAPID"
  }

  min_master_version = 1.28
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "cpu-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = "n1-standard-1"
    tags         = ["gke-node", "bzmarke-tpu-test"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_upgrade = true
    auto_repair = true
  }
}

resource "google_container_node_pool" "tpu_nodes" {
  provider = google-beta
  project = var.project_id
  name = "tpu-pool"
  location = var.region
  cluster = google_container_cluster.primary.name
  node_count = 1
  node_locations = [
    "${var.region}-b",
  ]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    machine_type = var.machine_type
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    service_account = "gke-alpha-svc-acct@tpu-pytorch.iam.gserviceaccount.com"
  }
  placement_policy {
    type = "COMPACT"
    tpu_topology = "2x2x1"
  }

  management {
    auto_upgrade = true
    auto_repair = true
  }
}
