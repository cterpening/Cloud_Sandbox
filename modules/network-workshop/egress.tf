# Run Command needs outbound HTTPS. NAT provides egress without public VM NICs.
resource "azurerm_public_ip" "egress" {
  name                = "${local.name}-egress"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}
resource "azurerm_nat_gateway" "workshop" {
  name                    = "${local.name}-egress"
  resource_group_name     = data.azurerm_resource_group.sandbox.name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 4
  tags                    = local.tags
}
resource "azurerm_nat_gateway_public_ip_association" "workshop" {
  nat_gateway_id       = azurerm_nat_gateway.workshop.id
  public_ip_address_id = azurerm_public_ip.egress.id
}
resource "azurerm_subnet_nat_gateway_association" "workshop" {
  for_each       = azurerm_subnet.workshop
  subnet_id      = each.value.id
  nat_gateway_id = azurerm_nat_gateway.workshop.id
}
resource "azurerm_network_security_group" "client" {
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
  name                = "${local.name}-client"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  tags                = local.tags
}
resource "azurerm_subnet_network_security_group_association" "client" {
  subnet_id                 = azurerm_subnet.workshop["client"].id
  network_security_group_id = azurerm_network_security_group.client.id
}
