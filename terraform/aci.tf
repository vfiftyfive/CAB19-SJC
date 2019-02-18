provider "aci" {
  username    = "api_user"
  private_key = "${var.aci_private_key}"
  cert_name   = "${var.aci_cert_name}"
  url         = "https://172.16.255.10"
  insecure    = true
}

resource "aci_tenant" "terraform_ten" {
  name = "terraform_ten"
}

resource "aci_vrf" "vrf1" {
  tenant_dn = "${aci_tenant.terraform_ten.id}"
  name      = "vrf1"
}

resource "aci_bridge_domain" "bd1" {
  tenant_dn          = "${aci_tenant.terraform_ten.id}"
  relation_fv_rs_ctx = "${aci_vrf.vrf1.name}"
  name               = "bd1"
}

resource "aci_subnet" "bd1_subnet" {
  bridge_domain_dn = "${aci_bridge_domain.bd1.id}"
  name             = "Subnet"
  ip               = "${var.bd_subnet}"
}

resource "aci_application_profile" "app1" {
  tenant_dn = "${aci_tenant.terraform_ten.id}"
  name      = "app1"
}

resource "aci_application_epg" "epg1" {
  application_profile_dn = "${aci_application_profile.app1.id}"
  name                   = "epg1"
  relation_fv_rs_bd      = "${aci_bridge_domain.bd1.name}"
  relation_fv_rs_dom_att = ["${var.vmm_domain_dn}"]
  relation_fv_rs_cons    = ["${aci_contract.contract_epg1_epg2.name}"]
}

resource "aci_application_epg" "epg2" {
  application_profile_dn = "${aci_application_profile.app1.id}"
  name                   = "epg2"
  relation_fv_rs_bd      = "${aci_bridge_domain.bd1.name}"
  relation_fv_rs_dom_att = ["${var.vmm_domain_dn}"]
  relation_fv_rs_prov    = ["${aci_contract.contract_epg1_epg2.name}"]
}

resource "aci_contract" "contract_epg1_epg2" {
  tenant_dn = "${aci_tenant.terraform_ten.id}"
  name      = "Web"
}

resource "aci_contract_subject" "Web_subject1" {
  contract_dn                  = "${aci_contract.contract_epg1_epg2.id}"
  name                         = "Subject"
  relation_vz_rs_subj_filt_att = ["${aci_filter.allow_https.name}"]
}

resource "aci_filter" "allow_https" {
  tenant_dn = "${aci_tenant.terraform_ten.id}"
  name      = "allow_https"
}

resource "aci_filter_entry" "https" {
  name        = "https"
  filter_dn   = "${aci_filter.allow_https.id}"
  ether_t     = "ip"
  prot        = "tcp"
  d_from_port = "https"
  d_to_port   = "https"
  stateful    = "yes"
}

provider "vsphere" {
  user                 = "${var.vsphere_user}"
  password             = "${var.vsphere_password}"
  vsphere_server       = "${var.vsphere_server}"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_network" "vm1_net" {
  depends_on = ["aci_application_epg.epg1"],
  name          = "${format("%v|%v|%v", aci_tenant.terraform_ten.name, aci_application_profile.app1.name, aci_application_epg.epg1.name)}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "vm2_net" {
  depends_on = ["aci_application_epg.epg2"]
  name          = "${format("%v|%v|%v", aci_tenant.terraform_ten.name, aci_application_profile.app1.name, aci_application_epg.epg2.name)}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_datastore" "ds" {
  name          = "${var.vsphere_datastore}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cl" {
  name          = "${var.vsphere_compute_cluster}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "${var.vsphere_template}"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

resource "vsphere_virtual_machine" "aci_vm1" {
  count            = 1
  name             = "${var.aci_vm1_name}"
  resource_pool_id = "${data.vsphere_compute_cluster.cl.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"

  num_cpus = 8
  memory   = 24576
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  disk {
    label = "disk0"
    size  = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  disk {
    unit_number = 1
    label       = "disk1"
    size        = 40
  }

  folder = "${var.folder}"

  network_interface {
    network_id   = "${data.vsphere_network.vm1_net.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    linked_clone  = "true"
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.aci_vm1_name}"
        domain    = "${var.domain_name}"
      }

      network_interface {
        ipv4_address = "${var.aci_vm1_address}"
        ipv4_netmask = "24"
      }

      ipv4_gateway    = "${var.gateway}"
      dns_server_list = "${var.dns_list}"
      dns_suffix_list = "${var.dns_search}"
    }
  }
}
resource "vsphere_virtual_machine" "aci_vm2" {
  count            = 1
  name             = "${var.aci_vm2_name}"
  resource_pool_id = "${data.vsphere_compute_cluster.cl.resource_pool_id}"
  datastore_id     = "${data.vsphere_datastore.ds.id}"

  num_cpus = 8
  memory   = 24576
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  disk {
    label = "disk0"
    size  = "${data.vsphere_virtual_machine.template.disks.0.size}"
  }

  disk {
    unit_number = 1
    label       = "disk1"
    size        = 40
  }

  folder = "${var.folder}"

  network_interface {
    network_id   = "${data.vsphere_network.vm2_net.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  clone {
    linked_clone  = "true"
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.aci_vm2_name}"
        domain    = "${var.domain_name}"
      }

      network_interface {
        ipv4_address = "${var.aci_vm2_address}"
        ipv4_netmask = "24"
      }

      ipv4_gateway    = "${var.gateway}"
      dns_server_list = "${var.dns_list}"
      dns_suffix_list = "${var.dns_search}"
    }
  }
}

