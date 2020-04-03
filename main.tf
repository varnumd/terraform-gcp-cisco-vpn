provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials_file
}

provider "google-beta" {
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = var.gcp_credentials_file
}

/*
 * Terraform networking resources for GCP.
 */

resource "google_compute_ha_vpn_gateway" "ha_gateway1" {
  provider = google-beta
  region   = "us-central1"
  name     = "ha-vpn-1"
  network  = google_compute_network.tf_vpc_net1.self_link
}

resource "google_compute_external_vpn_gateway" "external_gateway" {
  provider        = google-beta
  name            = "hq-cisco"
  redundancy_type = "SINGLE_IP_INTERNALLY_REDUNDANT"
  description     = "An externally managed VPN gateway"
  interface {
    id         = 0
    ip_address = var.on_prem_ip1
  }
}

resource "google_compute_network" "tf_vpc_net1" {
  name                    = "tf-vpc-net-1"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tf_vpc_net1_subnet1" {
  name          = "ha-vpn-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.tf_vpc_net1.self_link
}

resource "google_compute_subnetwork" "tf_vpc_net1_subnet2" {
  name          = "ha-vpn-subnet-2"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-west1"
  network       = google_compute_network.tf_vpc_net1.self_link
}

resource "google_compute_router" "router1" {
  name    = "ha-vpn-router-1"
  network = google_compute_network.tf_vpc_net1.name
  bgp {
    asn = var.gcp_asn
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  provider                        = google-beta
  name                            = "ha-vpn-tunnel1"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway1.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.self_link
  peer_external_gateway_interface = 0
  shared_secret                   = var.gcp_shared_secret
  router                          = google_compute_router.router1.self_link
  vpn_gateway_interface           = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  provider                        = google-beta
  name                            = "ha-vpn-tunnel2"
  region                          = "us-central1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.ha_gateway1.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.external_gateway.self_link
  peer_external_gateway_interface = 0
  shared_secret                   = var.gcp_shared_secret
  router                          = google_compute_router.router1.self_link
  vpn_gateway_interface           = 1
}

resource "google_compute_router_interface" "router1_interface1" {
  name       = "router1-interface1"
  router     = google_compute_router.router1.name
  region     = "us-central1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "router1-peer1"
  router                    = google_compute_router.router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = var.on_prem_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface1.name
}

resource "google_compute_router_interface" "router1_interface2" {
  name       = "router1-interface2"
  router     = google_compute_router.router1.name
  region     = "us-central1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "router1_peer2" {
  name                      = "router1-peer2"
  router                    = google_compute_router.router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = var.on_prem_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.router1_interface2.name
}


/*
 * Terraform compute resources for GCP.
 */

resource "google_compute_instance" "vm_instance1" {
  name         = "terraform-intance-1"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    # Using terraform interpolation, we'll reference the self_link here pointing to the newly created network
    subnetwork = google_compute_subnetwork.tf_vpc_net1_subnet1.self_link
    access_config {
    }
  }
}

resource "google_compute_instance" "vm_instance2" {
  name         = "terraform-intance-2"
  machine_type = "f1-micro"
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    # Using terraform interpolation, we'll reference the self_link here pointing to the newly created network
    subnetwork = google_compute_subnetwork.tf_vpc_net1_subnet2.self_link
    access_config {
    }
  }
}

resource "google_compute_instance" "vm_instance3" {
  name         = "terraform-intance-3"
  machine_type = "f1-micro"
  zone         = "us-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    # Using terraform interpolation, we'll reference the self_link here pointing to the newly created network
    subnetwork = google_compute_subnetwork.tf_vpc_net1_subnet2.self_link
    access_config {
    }
  }
}

resource "google_compute_firewall" "tf_firewall" {
  name    = "terraform-firewall-base"
  network = google_compute_network.tf_vpc_net1.self_link



  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
}


/*
 * Terraform output variables for GCP.
 */


output "gcp_external_vpn_address_1" {
  value = google_compute_ha_vpn_gateway.ha_gateway1.vpn_interfaces.0.ip_address
}

output "gcp_external_vpn_address_2" {
  value = google_compute_ha_vpn_gateway.ha_gateway1.vpn_interfaces.1.ip_address
}

output "gcp_instance1_external_ip" {
  value = google_compute_instance.vm_instance1.network_interface.0.access_config.0.nat_ip
}

output "gcp_instance1_internal_ip" {
  value = google_compute_instance.vm_instance1.network_interface.0.network_ip
}

output "gcp_instance2_external_ip" {
  value = google_compute_instance.vm_instance2.network_interface.0.access_config.0.nat_ip
}

output "gcp_instance2_internal_ip" {
  value = google_compute_instance.vm_instance2.network_interface.0.network_ip
}
