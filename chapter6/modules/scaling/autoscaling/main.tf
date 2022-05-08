# Configure autoscaling
#
# The configuration below scales based on total incoming bytes to easily test
# the scaling functionality. To increase the load manually, a simple command
# can be used:
# for n in {1..1000}; do curl http://<load balancer IP>; done
resource "azurerm_monitor_autoscale_setting" "example" {
  location            = var.location
  name                = "${var.environment}-example-monitor-autoscale-setting"
  resource_group_name = var.resource_group_name
  target_resource_id  = var.scale_set_id

  profile { # Default autoscale profile
    name = "default"

    capacity {
      default = 2
      maximum = 10
      minimum = 1
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total" # Measure total incoming bytes
        metric_resource_id = var.scale_set_id
        operator           = "GreaterThan"
        statistic          = "Max" # Measure max total incoming bytes between VMs
        threshold          = 200000 # Trigger when the metric is over 100KB
        time_aggregation   = "Maximum" # Measure max total incoming bytes between time grains
        time_grain         = "PT1M" # Single measurement timeframe
        time_window        = "PT5M" # Measurement history length, in this case it will keep 5 time grains
      }

      scale_action {
        cooldown  = "PT5M" # How long should the rule wait before being applied again?
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total"
        metric_resource_id = var.scale_set_id
        operator           = "LessThan"
        statistic          = "Max"
        threshold          = 100000
        time_aggregation   = "Maximum"
        time_grain         = "PT1M"
        time_window        = "PT5M"
      }

      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
      }
    }
  }


  profile { # Profile recurring on weekends
    name = "weekends"

    capacity {
      default = 6 # Default capacity increased to 6
      maximum = 10
      minimum = 1
    }

    recurrence { # Triggers on 6:00 UTC on weekends
      days    = ["Saturday", "Sunday"]
      hours   = [6]
      minutes = [0]
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total" # Measure total incoming bytes
        metric_resource_id = var.scale_set_id
        operator           = "GreaterThan"
        statistic          = "Max" # Measure max total incoming bytes between VMs
        threshold          = 200000 # Trigger when the metric is over 100KB
        time_aggregation   = "Maximum" # Measure max total incoming bytes between time grains
        time_grain         = "PT1M" # Single measurement timeframe
        time_window        = "PT5M" # Measurement history length, in this case it will keep 5 time grains
      }

      scale_action {
        cooldown  = "PT5M" # How long should the rule wait before being applied again?
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Network In Total"
        metric_resource_id = var.scale_set_id
        operator           = "LessThan"
        statistic          = "Max"
        threshold          = 100000
        time_aggregation   = "Maximum"
        time_grain         = "PT1M"
        time_window        = "PT5M"
      }

      scale_action {
        cooldown  = "PT5M"
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
      }
    }
  }
}
