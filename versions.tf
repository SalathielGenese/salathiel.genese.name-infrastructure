terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.11.0"
    }
  }
}

provider "google" {
  credentials = var.gcp-credentials
  project     = local.project-id
  region      = local.region
}
