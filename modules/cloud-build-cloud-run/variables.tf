variable "launch-stage" {
  validation {
    error_message = "`var.launch-stage` MUST be either ALPHA, BETA or GA"
    condition     = contains(["ALPHA", "BETA", "GA"], var.launch-stage)
  }
  type = string
}
variable "gcp-credentials-secret-id" { type = string }
variable "repository-id" { type = string }
variable "module-name" { type = string }
variable "project-id" { type = string }
variable "region" { type = string }
variable "domain" { type = string }
variable "branch" { type = string }
variable "www" {
  default = false
  type    = bool
}
