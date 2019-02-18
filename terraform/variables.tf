variable "vsphere_server" {
  default = "192.168.81.50"
}

variable "vsphere_user" {
  default = "administrator@vsphere.local"
}

variable "vsphere_password" {
  default = "C!5co123"
}

variable "vsphere_datacenter" {
  default = "uktme-01"
}

variable "net_mgmt" {
  default = "quarantine"
}

variable "vsphere_datastore" {
  default = "nvermand_esxi_nfs_datastore"
}

variable "vsphere_compute_cluster" {}

variable "vsphere_template" {
  default = "packer-centos-7"
}

variable "domain_name" {
  default = "uktme.cisco.com"
}

variable "folder" {}

variable "aci_private_key" {
  default = "/home/nvermand/fabric1_admin.key"
}

variable "aci_cert_name" {
  default = "admin_cert"
}

variable "vmm_domain_dn" {}

variable "provider_profile_dn" {
  default = "uni/vmmp-VMware"
}

variable "bd_subnet" {}

variable "gateway" {}

variable "aci_vm1_address" {}

variable "aci_vm2_address" {}

variable "aci_vm1_name" {}

variable "aci_vm2_name" {}

variable "dns_list" {
  default = ["10.52.248.72", "10.52.248.73"]
}

variable "dns_search" {
  default = ["uktme.cisco.com"]
}
