# checkov:skip=CKV2_AZURE_31:Jumphost subnet uses NSG via network_interface_security_group_association; direct subnet NSG not required
resource "azurerm_subnet" "jumphost_subnet" {
  count                = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                 = "${local.name_prefix}-jumphost-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aro_jumphost_subnet_cidr_block]
  service_endpoints    = ["Microsoft.ContainerRegistry"]
}

# Due to remote-exec issue Static allocation needs
# to be used - https://github.com/hashicorp/terraform/issues/21665
resource "azurerm_public_ip" "jumphost_pip" {
  count               = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"

  tags = var.tags
}

# checkov:skip=CKV_AZURE_119:Jumphost requires public IP for SSH access to private ARO clusters; security controlled via NSG
resource "azurerm_network_interface" "jumphost_nic" {
  count               = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jumphost_subnet[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jumphost_pip[0].id
  }

  tags = var.tags
}

resource "azurerm_network_security_group" "jumphost_nsg" {
  count               = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
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

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "jumphost_association" {
  count                     = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  network_interface_id      = azurerm_network_interface.jumphost_nic[0].id
  network_security_group_id = azurerm_network_security_group.jumphost_nsg[0].id
}

resource "azurerm_linux_virtual_machine" "jumphost_vm" {
  count               = var.api_server_profile == "Private" || var.ingress_profile == "Private" ? 1 : 0
  name                = "${local.name_prefix}-jumphost"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v3"
  admin_username      = "aro"

  network_interface_ids = [
    azurerm_network_interface.jumphost_nic[0].id,
  ]

  admin_ssh_key {
    username   = "aro"
    public_key = file(var.jumphost_ssh_public_key_path)
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
      host        = azurerm_public_ip.jumphost_pip[0].ip_address
      user        = "aro"
      private_key = file(var.jumphost_ssh_private_key_path)
    }
    inline = [
      "sudo dnf install telnet wget bash-completion -y",
      "wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${local.aro_version}/openshift-client-linux.tar.gz",
      "tar -xvf openshift-client-linux.tar.gz",
      "sudo mv oc kubectl /usr/bin/",
      "oc completion bash > oc_bash_completion",
      "sudo cp oc_bash_completion /etc/bash_completion.d/"
    ]
  }

  tags = var.tags
}
