terraform {
  backend "gcs" {
    bucket  = "mentoria-tfstate-staging"
    prefix  = "iac-load-balancer/state"
  }
}

provider "google" {
  project = "mentoria-iac-staging"
  region  = "us-central1"
}

data "google_compute_network" "orquestradores" {
  name = "orquestradores"
}

data "google_compute_subnetwork" "load-balancer" {
  name = "load-balancer"
}

resource "google_compute_firewall" "load-balancer" {
  name          = "load-balancer"
  network       = data.google_compute_network.orquestradores.name
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["load-balancer"]
  allow {
    protocol = "tcp"
    ports    = ["80", "22", "443", "4646"]
  }
}

module "compute_gcp" {
  source         = "github.com/mentoriaiac/iac-modulo-compute-gcp"
  count          = 2
  project        = "mentoria-iac-staging"
  instance_name  = "nginx-${count.index}"
  instance_image = "nginx-20220924001409"
  machine_type   = "e2-small"
  zone           = "us-central1-a"
  network        = data.google_compute_network.orquestradores.name
  subnetwork     = data.google_compute_subnetwork.load-balancer.name
  public_ip      = "ephemeral"

  labels = {
    value = "key"
  }
  tags = ["load-balancer"]
}
