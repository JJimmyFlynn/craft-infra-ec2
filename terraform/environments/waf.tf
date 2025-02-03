resource "aws_wafv2_web_acl" "managed_rules" {
  name  = module.this.id
  description = "Managed rule groups to be associated with Cloudfront"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "aws-managed-rules"
    sampled_requests_enabled   = false
  }

  /*=========== AWS Common Rules ===========*/
  rule {
    name     = "aws-common-rules"
    priority = 0

    override_action {
      none {}
    }


    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        // Craft's asset uploads trigger this rule
        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_BODY"
        }

        // Craft's asset uploads trigger this rule
        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-common-rules"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Known Bad Inputs ===========*/
  rule {
    name     = "aws-known-bad-inputs"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-known-bad-inputs"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Common SQL ===========*/
  rule {
    name     = "aws-sql-common"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-sql-common"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Common Linux ===========*/
  rule {
    name     = "aws-common-linux"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-common-linux"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Common Unix ===========*/
  rule {
    name     = "aws-common-unix"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesUnixRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-common-unix"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Common PHP ===========*/
  rule {
    name     = "aws-common-php"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-common-php"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS IP Reputation ===========*/
  rule {
    name     = "aws-ip-reputation"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-ip-reputation"
      sampled_requests_enabled   = false
    }
  }

  /*=========== AWS Bot Protection ===========*/
  rule {
    name     = "aws-bot-protection"
    priority = 7

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "aws-bot-protection"
      sampled_requests_enabled   = false
    }
  }
}


