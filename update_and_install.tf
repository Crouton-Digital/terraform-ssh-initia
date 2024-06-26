# Install Update
resource "null_resource" "update_system" {

  triggers = {
    update_packages = local.install_update_packages
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_update_packages ]
  }

  depends_on = []
}

# Install GO
resource "null_resource" "install_go" {

  triggers = {
    install_go = local.install_go
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_go ]
  }

  depends_on = [ null_resource.update_system, ]

}

# Install APP node project
resource "null_resource" "install_app" {

  triggers = {
    install_app = local.install_app
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.install_app ]
  }

  depends_on = [ null_resource.install_go, ]

}

resource "null_resource" "init_node" {

  triggers = {
    init_node = local.init_node
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.init_node ]
  }

  depends_on = [ null_resource.install_app, ]

}

resource "null_resource" "web_service" {

  triggers = {
    web_service = local.web_service
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.web_service ]
  }

  depends_on = [ null_resource.init_node, ]

}

resource "null_resource" "pruning_setting" {

  triggers = {
    pruning_setting = local.pruning_setting
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.pruning_setting ]
  }

  depends_on = [ null_resource.web_service, ]

}

resource "null_resource" "restart_service" {

  triggers = {
    restart_service = local.restart_service
    pruning_setting = null_resource.pruning_setting.id
    web_service     = null_resource.web_service.id
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.restart_service ]
  }

  depends_on = [ null_resource.web_service, null_resource.pruning_setting, ]

}

resource "null_resource" "snapshot_node" {
  count = var.enable_snapshot_recovery == "true" ? 1 : 0

  triggers = {
    snapshot_node = local.snapshot_node
  }

  connection {
    user           = var.ssh_host_user
    private_key    = file(var.ssh_host_private_key_file)
    host           = var.ssh_host_ip
    port           = var.ssh_host_port
  }

  provisioner "remote-exec" {
    inline = [ local.snapshot_node ]
  }

  depends_on = [ null_resource.restart_service, ]

}

