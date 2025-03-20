terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "~> 4.123.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

resource "oci_core_instance" "ampere_instance" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  display_name        = "ampere-instance"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  source_details {
    source_type = "image"
    source_id   = var.image_id
  }

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = true
  }

  # デバッグ用のメッセージ出力
  provisioner "local-exec" {
    command = "echo 'A1インスタンスが正常に作成されました！'"
  }
}