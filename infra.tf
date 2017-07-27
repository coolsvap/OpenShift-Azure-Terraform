resource "azurerm_availability_set" "osinfraas" {
  name                = "${var.openshift_azure_resource_prefix}-as-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"
  managed             = true
}

resource "azurerm_network_interface" "osinfranic" {
  name                = "${var.openshift_azure_resource_prefix}-nic-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = "${azurerm_subnet.osinfrasubnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_public_ip" "osinfraip" {
  name                         = "${var.openshift_azure_resource_prefix}-vip-infra-${var.openshift_azure_resource_suffix}"
  location                     = "${var.openshift_azure_region}"
  resource_group_name          = "${azurerm_resource_group.osrg.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "osinfralb" {
  name                = "${var.openshift_azure_resource_prefix}-nlb-infra-${var.openshift_azure_resource_suffix}"
  location            = "${var.openshift_azure_region}"
  resource_group_name = "${azurerm_resource_group.osrg.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.osinfraip.id}"
  }
}

resource "azurerm_virtual_machine" "osinfravm" {
  name                  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
  count                 = "${var.openshift_azure_infra_vm_count}"
  location              = "${var.openshift_azure_region}"
  resource_group_name   = "${azurerm_resource_group.osrg.name}"
  network_interface_ids = ["${azurerm_network_interface.osinfranic.id}"]
  availability_set_id   = "${azurerm_availability_set.osinfraas.id}"
  vm_size               = "${var.openshift_azure_infra_vm_size}"

  storage_image_reference {
    publisher = "${var.openshift_azure_vm_os["publisher"]}"
    offer     = "${var.openshift_azure_vm_os["offer"]}"
    sku       = "${var.openshift_azure_vm_os["sku"]}"
    version   = "${var.openshift_azure_vm_os["version"]}"
  }

  storage_os_disk {
    name              = "osdiskinfra"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.openshift_azure_resource_prefix}-vm-infra-${var.openshift_azure_resource_suffix}-${format("%01d", count.index+1)}"
    admin_username = "${var.openshift_azure_vm_username}"
    admin_password = "${uuid()}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.openshift_azure_vm_username}/.ssh/authorized_keys"
      key_data = "${var.openshift_azure_ssh_key}"
    }
  }
}
