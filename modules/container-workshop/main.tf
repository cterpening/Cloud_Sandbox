data "azurerm_resource_group" "sandbox" { name = var.resource_group_name }
resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_container_group" "workshop" {
  name                = "ws-container-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.sandbox.name
  location            = var.location
  os_type             = "Linux"
  ip_address_type     = "None"
  restart_policy      = "Always"
  container {
    name     = "workshop"
    image    = var.container_image
    cpu      = 1
    memory   = 1
    commands = ["python", "-u", "-c", file("${path.module}/../../apps/workshop/container_app.py")]
    environment_variables = {
      APP_VERSION    = var.app_version
      BROKEN_STARTUP = tostring(var.broken_startup)
      PORT           = "8080"
    }
    liveness_probe {
      http_get {
        path   = "/api/health"
        port   = 8080
        scheme = "http"
      }
      initial_delay_seconds = 10
      period_seconds        = 10
      failure_threshold     = 3
      timeout_seconds       = 3
    }
  }
  tags = { project = "container-playground", purpose = "disposable-learning", managed_by = "terraform" }
}
