# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}
variable "hcloud_ssh_key_fingerprint" {}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

data "hcloud_ssh_key" "ssh_key" {
  fingerprint = "${var.hcloud_ssh_key_fingerprint}"
}

# Create a server
resource "hcloud_server" "monitoring" {
  name        = "mon-core"
  image       = "debian-10"
  server_type = "cx11"
  ssh_keys    = ["${data.hcloud_ssh_key.ssh_key.id}"]
}

#output "server_ip" {
#  value = "${hcloud_server.test.ipv4_address}"
#}
