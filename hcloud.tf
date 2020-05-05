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
  server_type = "cx21"
  ssh_keys    = ["${data.hcloud_ssh_key.ssh_key.id}"]


  provisioner "remote-exec" {
    inline = [
      "useradd -m -d /home/ansible -s /bin/bash ansible",
      "echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
    ]
    connection {
      type = "ssh"
      user = "root"
      host = self.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = "cat ~/.ssh/id_rsa.pub | ssh -o 'StrictHostKeyChecking no' root@${self.ipv4_address} 'mkdir -p /home/ansible/.ssh && cat >>  /home/ansible/.ssh/authorized_keys && chmod -R 700 /home/ansible/.ssh && chown -R ansible:ansible /home/ansible/.ssh' && export ANSIBLE_VAULT_PASSWORD_FILE=~/Documents/ansible/.vault_pass"
  }
}

  
data "template_file" "inventory" {
    template = "${file("templates/ansible_inventory.tpl")}"

    vars = {
      host_ip = "${hcloud_server.monitoring.ipv4_address}"
    }
}

resource "null_resource" "update_inventory" {

    triggers = {
        template = "${data.template_file.inventory.rendered}"
    }

    provisioner "local-exec" {
        command = "echo '${data.template_file.inventory.rendered}' > ~/Documents/ansible/inventory.yml"
    }
}



output "server_ip" {
  value = "${hcloud_server.monitoring.ipv4_address}"
}
