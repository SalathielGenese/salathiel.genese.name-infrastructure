#
# GCP Cloud Run
#
resource "google_cloud_run_v2_service" "web" {
  location     = var.region
  launch_stage = var.launch-stage
  ingress      = "INGRESS_TRAFFIC_ALL"
  name         = "${var.project-id}-web-${var.module-name}"
  template {
    volumes {
      name = "secrets"
      secret {
        default_mode = 292
        secret       = var.gcp-credentials-secret-id
        items {
          version = "latest"
          path    = "gcp-credentials"
        }
      }
    }
    containers {
      volume_mounts {
        name       = "secrets"
        mount_path = "/opt/secrets"
      }
      env {
        value = "${var.project-id}-web"
        name  = "GCP_DATASTORE_DATABASE"
      }
      env {
        name  = "GCP_CREDENTIALS"
        value = "/opt/secrets/gcp-credentials"
      }
      env {
        name  = "GOOGLE_CLOUD_CREDENTIALS"
        value = "/opt/secrets/gcp-credentials"
      }
      image = "${var.region}-docker.pkg.dev/${var.project-id}/${var.project-id}-web/${var.project-id}-web-${var.module-name}:latest"
    }
  }
}
resource "google_cloud_run_v2_service_iam_member" "web--iam--run" {
  #  Google Cloud Run needs be allowed to accept public traffic
  name   = google_cloud_run_v2_service.web.name
  role   = "roles/run.invoker"
  member = "allUsers"
}
resource "google_cloud_run_domain_mapping" "web" {
  location = var.region
  for_each = toset(var.www ? [".", "www."] : ["."])
  name     = "." == each.value ? var.domain : "${each.value}${var.domain}"

  metadata {
    namespace = var.project-id
  }

  spec {
    force_override = true
    route_name     = google_cloud_run_v2_service.web.name
  }
}
#
# GCP Cloud Build
#
resource "google_cloudbuild_trigger" "web" {
  name     = "${var.project-id}-web-${var.module-name}"
  location = var.region

  repository_event_config {
    repository = var.repository-id
    push {
      branch = var.branch
    }
  }

  build {
    step {
      # Build Docker image for PROD
      script = templatefile("${path.module}/cloud-build.sh.tfpl", {
        GCP_CREDENTIALS_SECRET_ID = var.gcp-credentials-secret-id,
        MODULE                    = var.module-name,
        PROJECT                   = var.project-id,
      })
      name = "gcr.io/cloud-builders/docker"
      env  = [
        "COMMIT_SHA=$COMMIT_SHA",
        "LOCATION=$LOCATION",
      ]
    }
  }
}
