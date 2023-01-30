resource "azurerm_subnet" "jumphost-subnet" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                 = "${local.name_prefix}-jumphost-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_jumphost_subnet_cidr_block]
  service_endpoints    = ["Microsoft.ContainerRegistry"]

}

# Due to remote-exec issue Static allocation needs
# to be used - https://github.com/hashicorp/terraform/issues/21665
resource "azurerm_public_ip" "jumphost-pip" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags                = var.tags

}

resource "azurerm_network_interface" "jumphost-nic" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumphost-subnet.0.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumphost-pip.0.id
  }
  tags = var.tags
}

resource "azurerm_network_security_group" "jumphost-nsg" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost-nsg"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "association" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  network_interface_id      = azurerm_network_interface.jumphost-nic.0.id
  network_security_group_id = azurerm_network_security_group.jumphost-nsg.0.id
}

resource "azurerm_linux_virtual_machine" "jumphost-vm" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "aro"

  network_interface_ids = [
    azurerm_network_interface.jumphost-nic.0.id,
  ]

  admin_ssh_key {
    username   = "aro"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8.2"
    version   = "8.2.2021040911"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = azurerm_public_ip.jumphost-pip.0.ip_address
      user        = "aro"
      private_key = file("~/.ssh/id_rsa")
    }
    inline = [
      "sudo dnf install telnet wget bash-completion -y",
      "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz",
      "tar -xvf openshift-client-linux.tar.gz",
      "sudo mv oc kubectl /usr/bin/",
      "oc completion bash > oc_bash_completion",
      "sudo cp oc_bash_completion /etc/bash_completion.d/"
    ]
  }

  tags = var.tags
}

output "public_ip" {
  value = try(azurerm_public_ip.jumphost-pip.0.ip_address,null)
}
