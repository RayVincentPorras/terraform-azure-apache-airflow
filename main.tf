provider "azurerm" {
  version = "~> 1.15"
}

resource "azurerm_resource_group" "AirflowResourceGroup" {
  name     = "${var.airflow_rg_name}"
  location = "West US 2"
}

resource "azurerm_app_service_plan" "AirflowAppServicePlan" {
  name = "${var.airflow_asp_name}"
  location = "${azurerm_resource_group.AirflowResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.AirflowResourceGroup.name}"

  kind = "Linux"
  
  sku {
    tier = "PremiumV2"
    size = "P1V2"
  }
  
  reserved = "true" 
}

resource "azurerm_app_service" "AirflowAppService" {
  name  = "${var.airflow_as_name}"
  location = "${azurerm_resource_group.AirflowResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.AirflowResourceGroup.name}"
  app_service_plan_id = "${azurerm_app_service_plan.AirflowAppServicePlan.id}"
  
  app_settings = {
    AIRFLOW__CORE__SQL_ALCHEMY_CONN = "postgresql://${azurerm_postgresql_server.PostgreSQLServer.administrator_login}@${azurerm_postgresql_server.PostgreSQLServer.name}:${azurerm_postgresql_server.PostgreSQLServer.administrator_login_password}@${azurerm_postgresql_server.PostgreSQLServer.name}.postgres.database.azure.com:5432/${azurerm_postgresql_database.PostgreSQLDatabase.name}"
    AIRFLOW__CORE__LOAD_EXAMPLES = "true"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = true
  }
  
  site_config {
    linux_fx_version = "DOCKER|puckel/docker-airflow:latest"
    always_on = "true"
  }
  
  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_postgresql_server" "PostgreSQLServer" {
  name                = "${var.airflow_PSQLserver_name}"
  location            = "${azurerm_resource_group.AirflowResourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.AirflowResourceGroup.name}"

  sku {
    name     = "GP_Gen5_2"
    capacity = 2
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }

  administrator_login          = "${var.airflow_PSQLserver_admin}"
  administrator_login_password = "${var.airflow_PSQLserver_password}"
  version                      = "9.6"
  ssl_enforcement              = "Enabled"
}

resource "azurerm_postgresql_firewall_rule" "PostgreSQLServerFireWallRules" {
  name                = "office"
  resource_group_name = "${azurerm_resource_group.AirflowResourceGroup.name}"
  server_name         = "${azurerm_postgresql_server.PostgreSQLServer.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_postgresql_database" "PostgreSQLDatabase" {
  name                = "${var.airflow_PSQLdb_name}"
  resource_group_name = "${azurerm_resource_group.AirflowResourceGroup.name}"
  server_name         = "${azurerm_postgresql_server.PostgreSQLServer.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
