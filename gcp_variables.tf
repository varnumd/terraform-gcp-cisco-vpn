/*
 * Terraform variable declarations for GCP.
 */


variable "gcp_credentials_file" {
  description = "Locate the GCP credentials file."
  type = string
}

variable gcp_project {
  description = "GCP Project"
  default = "terraform-testing-272920"
}

variable gcp_region {
  description = "Default to US Central."
  default = "us-central1"
}

variable gcp_zone {
  description = "Default to US Central1c."
  default = "us-central1-c"
}

variable on_prem_ip1 {
  description = "The IP of the on-prem VPN gateway"
  type = string
}

variable gcp_asn {
  description = "BGP ASN or GCP Cloud Router"
  default = 64997
}

variable on_prem_asn {
  description = "BGP ASN or On-Prem Router"
  default = 65000
}

variable gcp_shared_secret {
  description = "VPN shared secret"
  default = "d0v3r1a1d"
}

