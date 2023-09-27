# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC
resource "google_compute_network" "vpc" {
  name                    = "bzmarke-${var.project_id}-vpc"
  auto_create_subnetworks = "false"
  project = var.project_id
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "bzmarke-${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
  project = var.project_id
}
