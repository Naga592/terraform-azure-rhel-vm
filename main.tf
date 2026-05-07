provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test_rg" {
  name     = "rg-github-actions-test"
  location = "Canada Central"
}
