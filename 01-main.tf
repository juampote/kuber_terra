terraform {
  # This module is now only being tested with Terraform 0.14.x. However, to make upgrading easier, we are setting
  # 0.12.26 as the minimum version, as that version added support for required_providers with source URLs, making it
  # forwards compatible with 0.14.x code.
  required_version = ">= 0.12.26"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3.43.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3.43.0"
    }
  }
}

provider "google" {
  region  = var.region
  project = var.project
}

provider "google-beta" {
  region  = var.region
  project = var.project
}

resource "google_container_cluster" "pelado" {
  name    = "pelado"
  location  = "us-central1"
  remove_default_node_pool = true
  initial_node_count = 1

resource "google_container_node_pool" "primary_nodes" {
    name       = "pelado-nodes"
    location = "us-central1"
    cluster = google_container_cluster.pelado.name
    node_count = 1
    node_config {
     machine_type = "e2-medium"
     tags = ["pelado-nodes"]
    }
}

module "lb" {
  source                = "./modules/http-load-balancer"
  name                  = var.name
  project               = var.project
  url_map               = google_compute_url_map.urlmap.self_link
  dns_record_ttl        = var.dns_record_ttl
  enable_http           = var.enable_http
  ssl_certificates      = google_compute_ssl_certificate.certificate.*.self_link
  target_tags           = ["pelado-nodes"]
  ports                 = ["30000"]
}