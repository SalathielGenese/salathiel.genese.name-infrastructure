data "google_project" "web" {}
#
# GCP Cloud Build v2 Connection
#
data "google_secret_manager_secret" "web" {
  secret_id = var.gcp-github-connection-secret-name
}
data "google_secret_manager_secret_version" "web" {
  secret = data.google_secret_manager_secret.web.id
}
resource "google_cloudbuildv2_connection" "web" {
  location = local.region
  name     = local.username
  github_config {
    app_installation_id = var.gcp-github-connection-app-installation-id
    authorizer_credential {
      oauth_token_secret_version = data.google_secret_manager_secret_version.web.id
    }
  }
}
#
# GCP Cloud Build v2 Repository
#
resource "google_cloudbuildv2_repository" "web" {
  parent_connection = google_cloudbuildv2_connection.web.id
  project           = data.google_project.web.number
  name              = "${local.project-id}-web"
  remote_uri        = local.web-repository-uri
}
#
# GCP Artifact Registry
#
resource "google_artifact_registry_repository" "web" {
  repository_id = "${local.project-id}-web"
  format        = "DOCKER"
}
#
# GCP Managed DNS Zone
#
resource "google_dns_managed_zone" "web" {
  name        = local.project-id
  dns_name    = "${var.domain}."
  description = "Root domain"
  dnssec_config {
    state         = "on"
    non_existence = "nsec3"
    kind          = "dns#managedZoneDnsSecConfig"
    default_key_specs {
      key_length = 2048
      algorithm  = "rsasha256"
      key_type   = "keySigning"
      kind       = "dns#dnsKeySpec"
    }
    default_key_specs {
      key_length = 1024
      algorithm  = "rsasha256"
      key_type   = "zoneSigning"
      kind       = "dns#dnsKeySpec"
    }
  }
}
#
# GCP Secret Manager & its secrets
#
resource "google_secret_manager_secret" "gcp-credentials" {
  secret_id = "${local.project-id}-web-gcp-credentials"
  replication {
    auto {}
  }
}
resource "google_secret_manager_secret_version" "gcp-credentials-version" {
  secret      = google_secret_manager_secret.gcp-credentials.id
  secret_data = var.gcp-credentials
}
resource "google_secret_manager_secret_iam_member" "gcp-credentials--iam--compute" {
  #  Google Cloud Run actually runs on GCP Compute so this permission is necessary for container at runtime
  member    = "serviceAccount:${data.google_project.web.number}-compute@developer.gserviceaccount.com"
  secret_id = google_secret_manager_secret.gcp-credentials.id
  role      = "roles/secretmanager.secretAccessor"
}
#resource "google_secret_manager_secret_iam_member" "cloudbuild-iam-secretmanager" {
#  # TODO: Remove this unnecessary resource. Only Cloud Run will need access to this, through compute
#  member    = "serviceAccount:${data.google_project.web.number}@cloudbuild.gserviceaccount.com"
#  secret_id = google_secret_manager_secret.gcp-credentials.id
#  role      = "roles/secretmanager.secretAccessor"
#}
#
# GCP Databases
#
resource "google_firestore_database" "web" {
  delete_protection_state     = "DELETE_PROTECTION_ENABLED"
  name                        = "${local.project-id}-web"
  type                        = "DATASTORE_MODE"
  location_id                 = local.region
  concurrency_mode            = "OPTIMISTIC"
  app_engine_integration_mode = "DISABLED"
  deletion_policy             = "DELETE"
}
#module "staging" {
#  hdc-gcp-credentials-secret-id = google_secret_manager_secret.hdc-gcp-credentials.secret_id
#  repository-id                 = google_cloudbuildv2_repository.web.id
#  source                        = "./modules/cloud-build-cloud-run"
#  project-number                = data.google_project.this.number
#  domain                        = "staging.hopedaycameroon.com"
#  project-id                    = local.project
#  region                        = local.region
#  branch                        = "^staging$"
#  module-name                   = "staging"
#  domain-www-subdomain          = false
#}

module "staging" {
  gcp-credentials-secret-id = google_secret_manager_secret.gcp-credentials.secret_id
  repository-id             = google_cloudbuildv2_repository.web.id
  source                    = "./modules/cloud-build-cloud-run"
  domain                    = "staging.${var.domain}"
  project-id                = local.project-id
  region                    = local.region
  branch                    = "^staging$"
  module-name               = "staging"
  launch-stage              = "BETA"
}

module "prod" {
  gcp-credentials-secret-id = google_secret_manager_secret.gcp-credentials.secret_id
  repository-id             = google_cloudbuildv2_repository.web.id
  source                    = "./modules/cloud-build-cloud-run"
  project-id                = local.project-id
  region                    = local.region
  domain                    = var.domain
  branch                    = "^main$"
  module-name               = "prod"
  launch-stage              = "GA"
}
