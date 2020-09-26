# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}
variable "hcloud_ssh_key_fingerprint" {}
variable "ansible_password" {}
variable "admin_password" {}

# Configure the Hetzner Cloud Provider
provider "hcloud" {
  token = "${var.hcloud_token}"
}

data "hcloud_ssh_key" "ssh_key" {
  fingerprint = "${var.hcloud_ssh_key_fingerprint}"
}

# Create a server
resource "hcloud_server" "usergate" {
  name        = "usergate"
  image       = "debian-10"
  server_type = "cx11"
  ssh_keys    = ["${data.hcloud_ssh_key.ssh_key.id}"]


  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y unzip",
      "curl -L https://download.mikrotik.com/routeros/6.47.3/chr-6.47.3.img.zip | funzip | dd of=/dev/sda bs=1M",
      "reboot"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = self.ipv4_address
    }
  }

  provisioner "local-exec" {
    command =<<EOF
      sleep 60 && 
      scp  ~/.ssh/id_rsa.pub admin@${self.ipv4_address}:/ &&
      ssh admin@${self.ipv4_address} <<EOC
        /user group add name=ansible policy=local,ssh,ftp,reboot,read,write,policy,test,password,sensitive,!telnet,!winbox,!web,!sniff,!api,!romon,!dude,!tikapp
        /user add name=ansible group=ansible password=${var.ansible_password}
        /user ssh-keys import user=ansible public-key-file=id_rsa.pub
        /user set admin password=${var.admin_password}
EOC
    EOF
  }
}

resource "hcloud_network" "network" {
  name      = "hetzner-net"
  ip_range  = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "subnet" {
  network_id    = hcloud_network.network.id
  type          = "cloud"
  network_zone  = "eu-central"
  ip_range      = "10.0.0.0/24"
}

resource "hcloud_server_network" "srvnetwork" {
  server_id   = hcloud_server.usergate.id
  network_id  = hcloud_network.network.id
  ip          = "10.0.0.9"
}

resource "hcloud_network_route" "nmc3" {
  network_id = hcloud_network.network.id
  destination = "10.3.0.0/16"
  gateway = "10.0.0.5"
}
resource "hcloud_network_route" "nmc4" {
  network_id = hcloud_network.network.id
  destination = "10.4.0.0/16"
  gateway = "10.0.0.5"
}

resource "hcloud_network_route" "nmc5" {
  network_id = hcloud_network.network.id
  destination = "10.5.0.0/16"
  gateway = "10.0.0.5"
}
resource "hcloud_network_route" "nmc6" {
  network_id = hcloud_network.network.id
  destination = "10.6.0.0/16"
  gateway = "10.0.0.5"
}
resource "hcloud_network_route" "nmc254" {
  network_id = hcloud_network.network.id
  destination = "10.254.0.0/24"
  gateway = "10.0.0.5"
}
resource "hcloud_network_route" "nmc253" {
  network_id = hcloud_network.network.id
  destination = "10.253.0.0/24"
  gateway = "10.0.0.9"
}

output "server_ip" {
  value = "${hcloud_server.usergate.ipv4_address}"
}
