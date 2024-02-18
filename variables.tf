#
# Locals
#
locals {
  region             = "europe-west1"
  username           = "SalathielGenese"
  project-id         = "salathiel-genese-name"
  web-repository-uri = "https://github.com/SalathielGenese/salathiel.genese.name.git"
}
#
# Variables
#
variable "domain" {
  type      = string
  sensitive = true
}
variable "gcp-credentials" {
  type      = string
  sensitive = true
}
variable "gcp-github-connection-secret-name" {
  type      = string
  sensitive = true
}
variable "gcp-github-connection-app-installation-id" {
  type      = number
  sensitive = true
}
