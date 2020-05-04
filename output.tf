data "template_file" "ansible_inventory" {
  template = "${file("templates/ansible_inventory.tpl")}"
  vars = {
    host_ip = "${hcloud_server.monitoring.ipv4_address}"
  }
}

output "ansible_inventory" {
  value = "${data.template_file.ansible_inventory.rendered}"
}
