# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {}
variable "hcloud_ssh_key_fingerprint" {}
variable "ansible_password" {}

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
        /user remove admin
EOC
    EOF
  }
}

output "server_ip" {
  value = "${hcloud_server.usergate.ipv4_address}"
}
