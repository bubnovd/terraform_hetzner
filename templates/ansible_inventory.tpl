# vim: set ft=ansible_hosts:
[prometheus]
monitoring ansible_host=${host_ip} ansible_user=ansible

[grafana]
monitoring

[alertmanager]
monitoring

[node-exporter]
monitoring

[mikrotik-exporter]
monitoring

[blackbox-exporter]
monitoring
