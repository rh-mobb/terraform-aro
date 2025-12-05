locals {
  # helper local to keep code clean
  deny_policy_rule = {
    "effect" : "deny"
  }

  # helper local to keep code clean 
  deny_delete_policy_rule = {
    "effect" : "denyAction",
    "details" : {
      "actionNames" : [
        "delete"
      ]
    }
  }
}

#
# vnet
#
locals {
  deny_vnet_policy_name = "aro-${var.cluster_name}-deny-vnet"
  deny_vnet_policy_rule = var.apply_network_policies_to_all ? {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/virtualNetworks"
      }
    ]
    } : {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/virtualNetworks"
      },
      {
        "field" : "name",
        "equals" : var.vnet
      }
    ]
  }
}

resource "azurerm_policy_definition" "deny_vnet" {
  count = var.apply_vnet_policy ? 1 : 0

  name         = local.deny_vnet_policy_name
  display_name = local.deny_vnet_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_vnet_policy_rule,
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_vnet_delete" {
  count = var.apply_vnet_policy ? 1 : 0

  name         = "${local.deny_vnet_policy_name}-delete"
  display_name = "${local.deny_vnet_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_vnet_policy_rule,
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_vnet_initiative" {
  count = var.apply_vnet_policy ? 1 : 0

  name         = "${local.deny_vnet_policy_name}-initiative"
  display_name = "${local.deny_vnet_policy_name}-initiative"
  policy_type  = "Custom"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_vnet[0].id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_vnet_delete[0].id
  }
}

resource "azurerm_resource_group_policy_assignment" "deny_vnet_assignment" {
  count = var.apply_vnet_policy ? 1 : 0

  name                 = "${local.deny_vnet_policy_name}-assignment"
  display_name         = "${local.deny_vnet_policy_name}-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_vnet_initiative[0].id
  resource_group_id    = local.network_resource_group_id

  non_compliance_message {
    content = "Denied via ${local.deny_vnet_policy_name}-assignment"
  }
}

#
# subnet
#
locals {
  deny_subnet_policy_name = "aro-${var.cluster_name}-deny-subnet"
  deny_subnet_policy_rule = var.apply_network_policies_to_all ? {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/virtualNetworks/subnets"
      }
    ]
    } : {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/virtualNetworks/subnets"
      },
      {
        "field" : "id",
        "contains" : "${local.vnet_id}"
      }
    ]
  }
}

resource "azurerm_policy_definition" "deny_subnet" {
  count = var.apply_subnet_policy ? 1 : 0

  name         = local.deny_subnet_policy_name
  display_name = local.deny_subnet_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_subnet_policy_rule,
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_subnet_delete" {
  count = var.apply_subnet_policy ? 1 : 0

  name         = "${local.deny_subnet_policy_name}-delete"
  display_name = "${local.deny_subnet_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_subnet_policy_rule,
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_subnet_initiative" {
  count = var.apply_subnet_policy ? 1 : 0

  name         = "${local.deny_subnet_policy_name}-initiative"
  display_name = "${local.deny_subnet_policy_name}-initiative"
  policy_type  = "Custom"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_subnet[0].id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_subnet_delete[0].id
  }
}

resource "azurerm_resource_group_policy_assignment" "deny_subnet_assignment" {
  count = var.apply_subnet_policy ? 1 : 0

  name                 = "${local.deny_subnet_policy_name}-assignment"
  display_name         = "${local.deny_subnet_policy_name}-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_subnet_initiative[0].id
  resource_group_id    = local.network_resource_group_id

  non_compliance_message {
    content = "Denied via ${local.deny_subnet_policy_name}-assignment"
  }
}

#
# route table
#
locals {
  apply_route_table_policy     = var.apply_network_policies_to_all ? var.apply_route_table_policy : var.apply_route_table_policy && length(var.route_tables) > 0
  deny_route_table_policy_name = "aro-${var.cluster_name}-deny-route-table"
  deny_route_table_policy_rule = var.apply_network_policies_to_all ? {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/routeTables"
      },
      {
        "anyOf" : [{ "field" : "name", "exists" : true }]
      }
    ]
    } : {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/routeTables"
      },
      {
        "anyOf" : [for route_table in var.route_tables : { "field" : "name", "equals" : route_table }]
      }
    ]
  }
}

resource "azurerm_policy_definition" "deny_route_table" {
  count = local.apply_route_table_policy ? 1 : 0

  name         = local.deny_route_table_policy_name
  display_name = local.deny_route_table_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_route_table_policy_rule,
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_route_table_delete" {
  count = local.apply_route_table_policy ? 1 : 0

  name         = "${local.deny_route_table_policy_name}-delete"
  display_name = "${local.deny_route_table_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_route_table_policy_rule,
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_route_table_initiative" {
  count = local.apply_route_table_policy ? 1 : 0

  name         = "${local.deny_route_table_policy_name}-initiative"
  display_name = "${local.deny_route_table_policy_name}-initiative"
  policy_type  = "Custom"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_route_table[0].id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_route_table_delete[0].id
  }
}

resource "azurerm_resource_group_policy_assignment" "deny_route_table_assignment" {
  count = local.apply_route_table_policy ? 1 : 0

  name                 = "${local.deny_route_table_policy_name}-assignment"
  display_name         = "${local.deny_route_table_policy_name}-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_route_table_initiative[0].id
  resource_group_id    = local.network_resource_group_id

  non_compliance_message {
    content = "Denied via ${local.deny_route_table_policy_name}-assignment"
  }
}

#
# nat gateway
#
locals {
  apply_nat_gateway_policy     = var.apply_network_policies_to_all ? var.apply_nat_gateway_policy : var.apply_nat_gateway_policy && length(var.nat_gateways) > 0
  deny_nat_gateway_policy_name = "aro-${var.cluster_name}-deny-nat-gateway"
  deny_nat_gateway_policy_rule = var.apply_network_policies_to_all ? {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/natGateways"
      },
      {
        "anyOf" : [{ "field" : "name", "exists" : true }]
      }
    ]
    } : {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/natGateways"
      },
      {
        "anyOf" : [for nat_gateway in var.nat_gateways : { "field" : "name", "equals" : nat_gateway }]
      }
    ]
  }
}

resource "azurerm_policy_definition" "deny_nat_gateway" {
  count = local.apply_nat_gateway_policy ? 1 : 0

  name         = local.deny_nat_gateway_policy_name
  display_name = local.deny_nat_gateway_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_nat_gateway_policy_rule,
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_nat_gateway_delete" {
  count = local.apply_nat_gateway_policy ? 1 : 0

  name         = "${local.deny_nat_gateway_policy_name}-delete"
  display_name = "${local.deny_nat_gateway_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_nat_gateway_policy_rule,
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_nat_gateway_initiative" {
  count = local.apply_nat_gateway_policy ? 1 : 0

  name         = "${local.deny_nat_gateway_policy_name}-initiative"
  display_name = "${local.deny_nat_gateway_policy_name}-initiative"
  policy_type  = "Custom"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_nat_gateway[0].id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_nat_gateway_delete[0].id
  }
}

resource "azurerm_resource_group_policy_assignment" "deny_nat_gateway_assignment" {
  count = local.apply_nat_gateway_policy ? 1 : 0

  name                 = "${local.deny_nat_gateway_policy_name}-assignment"
  display_name         = "${local.deny_nat_gateway_policy_name}-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_nat_gateway_initiative[0].id
  resource_group_id    = local.network_resource_group_id

  non_compliance_message {
    content = "Denied via ${local.deny_nat_gateway_policy_name}-assignment"
  }
}

#
# nsg
#
locals {
  apply_nsg_policy     = var.apply_network_policies_to_all ? var.apply_nsg_policy : var.apply_nsg_policy && (var.network_security_group != null && var.network_security_group != "")
  deny_nsg_policy_name = "aro-${var.cluster_name}-deny-nsg"
  deny_nsg_policy_rule = var.apply_network_policies_to_all ? {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/networkSecurityGroups"
      }
    ]
    } : {
    "allOf" : [
      {
        "field" : "type",
        "equals" : "Microsoft.Network/networkSecurityGroups"
      },
      {
        "field" : "name",
        "equals" : var.network_security_group
      }
    ]
  }
}

resource "azurerm_policy_definition" "deny_nsg" {
  count = local.apply_nsg_policy ? 1 : 0

  name         = local.deny_nsg_policy_name
  display_name = local.deny_nsg_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_nsg_policy_rule,
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_nsg_delete" {
  count = local.apply_nsg_policy ? 1 : 0

  name         = "${local.deny_nsg_policy_name}-delete"
  display_name = "${local.deny_nsg_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : local.deny_nsg_policy_rule,
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_nsg_initiative" {
  count = local.apply_nsg_policy ? 1 : 0

  name         = "${local.deny_nsg_policy_name}-initiative"
  display_name = "${local.deny_nsg_policy_name}-initiative"
  policy_type  = "Custom"

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_nsg[0].id
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.deny_nsg_delete[0].id
  }
}

resource "azurerm_resource_group_policy_assignment" "deny_nsg_assignment" {
  count = local.apply_nsg_policy ? 1 : 0

  name                 = "${local.deny_nsg_policy_name}-assignment"
  display_name         = "${local.deny_nsg_policy_name}-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_nsg_initiative[0].id
  resource_group_id    = local.network_resource_group_id

  non_compliance_message {
    content = "Denied via ${local.deny_nsg_policy_name}-assignment"
  }
}

#
# managed resource group restrictions
#
locals {
  has_managed_resource_group = var.managed_resource_group != "" && var.managed_resource_group != null

  apply_dns_policy         = var.apply_dns_policy && local.has_managed_resource_group
  apply_private_dns_policy = var.apply_private_dns_policy && local.has_managed_resource_group
  apply_public_ip_policy   = var.apply_public_ip_policy && local.has_managed_resource_group
  apply_managed_policies = (
    local.apply_dns_policy ||
    local.apply_private_dns_policy ||
    local.apply_public_ip_policy ||
    var.apply_vnet_policy ||
    var.apply_subnet_policy ||
    local.apply_route_table_policy ||
    local.apply_nat_gateway_policy
  )

  deny_dns_policy_name              = "aro-${var.cluster_name}-deny-dns"
  deny_dns_zone_policy_name         = "aro-${var.cluster_name}-deny-dns-zone"
  deny_private_dns_policy_name      = "aro-${var.cluster_name}-deny-private-dns"
  deny_private_dns_zone_policy_name = "aro-${var.cluster_name}-deny-private-dns-zone"
  deny_public_ip_policy_name        = "aro-${var.cluster_name}-deny-public-ip"
}

resource "azurerm_policy_definition" "deny_dns" {
  count = local.apply_dns_policy ? 1 : 0

  name         = local.deny_dns_policy_name
  display_name = local.deny_dns_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/dnsZones/A"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_dns_delete" {
  count = local.apply_dns_policy ? 1 : 0

  name         = "${local.deny_dns_policy_name}-delete"
  display_name = "${local.deny_dns_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/dnsZones/A"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_dns_zone" {
  count = local.apply_dns_policy ? 1 : 0

  name         = local.deny_dns_zone_policy_name
  display_name = local.deny_dns_zone_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/dnsZones"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_dns_zone_delete" {
  count = local.apply_dns_policy ? 1 : 0

  name         = "${local.deny_dns_zone_policy_name}-delete"
  display_name = "${local.deny_dns_zone_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/dnsZones/A"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_private_dns" {
  count = local.apply_private_dns_policy ? 1 : 0

  name         = local.deny_private_dns_policy_name
  display_name = local.deny_private_dns_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/privateDnsZones/A"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_private_dns_delete" {
  count = local.apply_private_dns_policy ? 1 : 0

  name         = "${local.deny_private_dns_policy_name}-delete"
  display_name = "${local.deny_private_dns_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/privateDnsZones/A"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_private_dns_zone" {
  count = local.apply_private_dns_policy ? 1 : 0

  name         = local.deny_private_dns_zone_policy_name
  display_name = local.deny_private_dns_zone_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/privateDnsZones"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_private_dns_zone_delete" {
  count = local.apply_private_dns_policy ? 1 : 0

  name         = "${local.deny_private_dns_zone_policy_name}-delete"
  display_name = "${local.deny_private_dns_zone_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/privateDnsZones"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_public_ip" {
  count = local.apply_public_ip_policy ? 1 : 0

  name         = local.deny_public_ip_policy_name
  display_name = local.deny_public_ip_policy_name
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/publicIPAddresses"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_policy_rule
  })
}

resource "azurerm_policy_definition" "deny_public_ip_delete" {
  count = local.apply_public_ip_policy ? 1 : 0

  name         = "${local.deny_public_ip_policy_name}-delete"
  display_name = "${local.deny_public_ip_policy_name}-delete"
  policy_type  = "Custom"
  mode         = "All"

  policy_rule = jsonencode({
    "if" : {
      "allOf" : [
        {
          "field" : "type",
          "equals" : "Microsoft.Network/publicIPAddresses"
        },
        {
          "value" : "[resourceGroup().name]",
          "equals" : var.managed_resource_group
        },
      ]
    },
    "then" : local.deny_delete_policy_rule
  })
}

resource "azurerm_policy_set_definition" "deny_managed_initiative" {
  count = local.apply_managed_policies ? 1 : 0

  name         = "aro-${var.cluster_name}-deny-managed-initiative"
  display_name = "aro-${var.cluster_name}-deny-managed-initiative"
  policy_type  = "Custom"

  dynamic "policy_definition_reference" {
    for_each = compact([
      # objects strictly in the managed resource group
      local.apply_dns_policy ? azurerm_policy_definition.deny_dns[0].id : null,
      local.apply_dns_policy ? azurerm_policy_definition.deny_dns_delete[0].id : null,
      local.apply_dns_policy ? azurerm_policy_definition.deny_dns_zone[0].id : null,
      local.apply_dns_policy ? azurerm_policy_definition.deny_dns_zone_delete[0].id : null,
      local.apply_private_dns_policy ? azurerm_policy_definition.deny_private_dns[0].id : null,
      local.apply_private_dns_policy ? azurerm_policy_definition.deny_private_dns_delete[0].id : null,
      local.apply_private_dns_policy ? azurerm_policy_definition.deny_private_dns_zone[0].id : null,
      local.apply_private_dns_policy ? azurerm_policy_definition.deny_private_dns_zone_delete[0].id : null,
      local.apply_public_ip_policy ? azurerm_policy_definition.deny_public_ip[0].id : null,
      local.apply_public_ip_policy ? azurerm_policy_definition.deny_public_ip_delete[0].id : null,

      # also limit other network-related permissions as they are not needed within the managed resource group, e.g.
      # VNET object exist in the VNET resource group so we should restrict permissions here as well
      #
      # NOTE: we cannot restrict NSG permissions as the service still needs to create
      #       and delete a default NSG, even in a BYO-NSG scenario.
      var.apply_subnet_policy ? azurerm_policy_definition.deny_subnet[0].id : null,
      var.apply_subnet_policy ? azurerm_policy_definition.deny_subnet_delete[0].id : null,
      var.apply_vnet_policy ? azurerm_policy_definition.deny_vnet[0].id : null,
      var.apply_vnet_policy ? azurerm_policy_definition.deny_vnet_delete[0].id : null,
      local.apply_route_table_policy ? azurerm_policy_definition.deny_route_table[0].id : null,
      local.apply_route_table_policy ? azurerm_policy_definition.deny_route_table_delete[0].id : null,
      local.apply_nat_gateway_policy ? azurerm_policy_definition.deny_nat_gateway[0].id : null,
      local.apply_nat_gateway_policy ? azurerm_policy_definition.deny_nat_gateway_delete[0].id : null
    ])

    content {
      policy_definition_id = policy_definition_reference.value
    }
  }
}

resource "azurerm_subscription_policy_assignment" "deny_managed_assignment" {
  count = local.apply_managed_policies ? 1 : 0

  name                 = "aro-${var.cluster_name}-deny-managed-assignment"
  display_name         = "aro-${var.cluster_name}-deny-managed-assignment"
  policy_definition_id = azurerm_policy_set_definition.deny_managed_initiative[0].id
  subscription_id      = "/subscriptions/${var.subscription_id}"

  non_compliance_message {
    content = "Denied via aro-${var.cluster_name}-deny-managed-assignment"
  }
}
