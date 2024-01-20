terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

variable "gcp_project_name" {
  type = string
}
variable "gcp_project_region" {
  type    = string
  default = "us-central1"
}
variable "instance_machine_type" {
  type    = string
  default = "g2-standard-8" # 8 vCPU, 32 GB RAM
}
variable "instance_name" {
  type    = string
  default = "gcp-l4"
}
variable "instance_zone" {
  type    = string
  default = "us-central1-a"
}
variable "instance_gpu_type" {
  type    = string
  default = "nvidia-l4"
}
variable "instance_gpu_count" {
  type    = number
  default = 1
}
variable "tailscale_authkey" {
  type = string
}
variable "user_name" {
  type = string
}
variable "ssh_pubkey" {
  type = string
}

data "template_file" "setup_script" {
  template = file("${path.module}/setup.sh.tpl")

  vars = {
    tailscale_authkey = var.tailscale_authkey
    user_name         = var.user_name
    ssh_pubkey        = var.ssh_pubkey
  }
}


provider "google" {
  credentials = file("./gcloud-secret.json")

  project = var.gcp_project_name
  region  = var.gcp_project_region
}

resource "google_compute_instance" "default" {
  boot_disk {
    auto_delete = true

    initialize_params {
      # cuda 11.8 (12.0) with conda
      image = "projects/ml-images/global/images/c0-deeplearning-common-gpu-v20240111-debian-11-py310"
      # 75 GB size disk
      size = 75
      type = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  guest_accelerator {
    type  = var.instance_gpu_type
    count = var.instance_gpu_count
  }

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = var.instance_machine_type
  name         = var.instance_name

  network_interface {
    network = "default"

    access_config {
      network_tier = "PREMIUM"
    }
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "TERMINATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server", "https-server"]
  zone = var.instance_zone

  # 初期設定
  metadata_startup_script = data.template_file.setup_script.rendered
}
