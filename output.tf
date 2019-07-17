output "outbound_ip_addresses" {
  value = "${azurerm_app_service.AirflowAppService.outbound_ip_addresses}"
}
