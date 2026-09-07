data "azurerm_resource_group" "sandbox" { name = var.resource_group_name }
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  name = "ws-net-${random_string.suffix.result}"
  tags = { project = "network-detective", purpose = "disposable-learning", managed_by = "terraform" }
}
resource "azurerm_virtual_network" "workshop" {
  name                = local.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  address_space       = ["10.42.0.0/16"]
  tags                = local.tags
}
resource "azurerm_subnet" "workshop" {
  for_each                        = { client = "10.42.1.0/24", server = "10.42.2.0/24" }
  name                            = each.key
  resource_group_name             = data.azurerm_resource_group.sandbox.name
  virtual_network_name            = azurerm_virtual_network.workshop.name
  address_prefixes                = [each.value]
  default_outbound_access_enabled = false
}
resource "azurerm_network_security_group" "server" {
  security_rule {
    name                       = "azure-control-https"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  security_rule {
    name                       = "deny-other-internet"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
  name                = "${local.name}-server"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  security_rule {
    name                       = "client-to-api"
    priority                   = 100
    direction                  = "Inbound"
    access                     = var.fault == "nsg" ? "Deny" : "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.42.1.0/24"
    destination_address_prefix = "10.42.2.4"
  }
  security_rule {
    name                       = "deny-other-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = local.tags
}
resource "azurerm_subnet_network_security_group_association" "server" {
  subnet_id                 = azurerm_subnet.workshop["server"].id
  network_security_group_id = azurerm_network_security_group.server.id
}
resource "azurerm_network_interface" "workshop" {
  for_each            = { client = "10.42.1.4", server = "10.42.2.4" }
  name                = "${local.name}-${each.key}"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  ip_configuration {
    name                          = "private"
    subnet_id                     = azurerm_subnet.workshop[each.key].id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value
  }
  tags = local.tags
}
resource "azurerm_linux_virtual_machine" "workshop" {
  depends_on                      = [azurerm_subnet_nat_gateway_association.workshop, azurerm_nat_gateway_public_ip_association.workshop]
  for_each                        = toset(["client", "server"])
  name                            = "${local.name}-${each.key}"
  resource_group_name             = data.azurerm_resource_group.sandbox.name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = "workshop"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.workshop[each.key].id]
  admin_ssh_key {
    username   = "workshop"
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  custom_data = each.key == "server" ? base64encode(file("${path.module}/server-cloud-init.yaml")) : null
  tags        = local.tags
}
resource "azurerm_private_dns_zone" "workshop" {
  name                = "workshop.internal"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  tags                = local.tags
}
resource "azurerm_private_dns_zone_virtual_network_link" "workshop" {
  name                  = local.name
  resource_group_name   = data.azurerm_resource_group.sandbox.name
  private_dns_zone_name = azurerm_private_dns_zone.workshop.name
  virtual_network_id    = azurerm_virtual_network.workshop.id
  registration_enabled  = false
  tags                  = local.tags
}
resource "azurerm_private_dns_a_record" "api" {
  name                = "api"
  zone_name           = azurerm_private_dns_zone.workshop.name
  resource_group_name = data.azurerm_resource_group.sandbox.name
  ttl                 = 10
  records             = [var.fault == "dns" ? "10.42.2.99" : "10.42.2.4"]
  tags                = local.tags
}
