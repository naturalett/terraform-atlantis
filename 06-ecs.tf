module "atlantis" {
  source = "terraform-aws-modules/atlantis/aws"

  name = "atlantis"

  # ECS Container Definition
  atlantis = {
    docker_labels = {
      "com.datadoghq.ad.instances" : "[{\"openmetrics_endpoint\": \"http://%%host%%:4141/metrics\", \"namespace\": \"atlantis\", \"metrics\": [\"atlantis_builder_execution_error\", \"atlantis_builder_execution_success\", \"atlantis_builder_projects\", \"atlantis_project_plan_execution_failure\", \"atlantis_project_plan_execution_error\", \"atlantis_project_apply_execution_error\", \"atlantis_project_apply_execution_failure\"]}]",
      "com.datadoghq.ad.check_names" : "[\"openmetrics\"]",
      "com.datadoghq.ad.init_configs" : "[{}]"
    }
    command = ["/bin/bash", "-c", "git config --global url.\"https://oauth2:${data.aws_secretsmanager_secret_version.github_token_plaintext.secret_string}@github.com\".insteadOf https://github.com && /usr/local/bin/docker-entrypoint.sh server"]
    environment = [
      {
        name  = "ATLANTIS_DISABLE_REPO_LOCKING"
        value = "true"
      },
      {
        name  = "ATLANTIS_LOG_LEVEL"
        value = "info"
      },
      {
        name  = "ATLANTIS_SILENCE_NO_PROJECTS"
        value = "true"
      },
      {
        name  = "ATLANTIS_WRITE_GIT_CREDS"
        value = "true"
      },
      {
        name  = "ATLANTIS_GH_USER"
        value = data.aws_secretsmanager_secret_version.github_user_plaintext.secret_string
      },
      {
        name  = "SHORT_ENV"
        value = "${var.env}"
      },
      {
        name  = "ATLANTIS_REPO_ALLOWLIST"
        value = join(",", var.atlantis_repo_allowlist)
      },
      {
        name : "ATLANTIS_REPO_CONFIG_JSON",
        value : jsonencode(yamldecode(file("${path.module}/server-atlantis.yaml"))),
      },
    ]
    secrets = [
      {
        name      = "ATLANTIS_GH_TOKEN"
        valueFrom = data.aws_secretsmanager_secret_version.github_token_plaintext.arn
      },
      {
        name      = "ATLANTIS_GH_WEBHOOK_SECRET"
        valueFrom = try(module.secrets_manager["github-webhook-secret"].secret_arn, "")
      },
    ]
    cpu    = "400"
    memory = "400"
  }

  # ECS Service
  service = {
    cpu    = "1024"
    memory = "2048"
    container_definitions = {
      datadog-agent = {
        name   = "datadog-agent"
        image  = "gcr.io/datadoghq/agent:7.46.0"
        memory = "400"
        cpu    = "400"
        environment = [
          {
            name  = "ECS_FARGATE",
            value = "true"
          },
          {
            name  = "DD_API_KEY",
            value = data.aws_secretsmanager_secret_version.datadog_api_key_plaintext.secret_string
          },
          {
            name  = "DD_SITE",
            value = "datadoghq.com"
          },
          {
            name  = "DD_PROMETHEUS_SCRAPE_ENABLED",
            value = "true"
          },
          {
            name  = "DD_PROMETHEUS_SCRAPE_SERVICE_ENDPOINTS",
            value = "true"
          },
          {
            name  = "DD_TAGS",
            value = "env:${var.env} region:${var.region}"
          }
        ]
        readonly_root_filesystem = false
      }
    }
    task_exec_secret_arns = [
      data.aws_secretsmanager_secret_version.github_token_plaintext.arn,
      module.secrets_manager["github-webhook-secret"].secret_arn,
    ]
    task_exec_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
    # Provide Atlantis permission necessary to create/destroy resources
    tasks_iam_role_policies = {
      AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
  }
  service_subnets = data.aws_subnets.subnet_ids_private.ids
  vpc_id          = data.aws_vpc.vpc.id

  # ALB
  alb_subnets = data.aws_subnets.subnet_ids_public.ids
  alb = {
    security_group_ingress_rules = merge([
      for ip in data.github_ip_ranges.ip_list.api_ipv4 : {
        "https-${replace(ip, ".", "-")}" = {
          from_port   = 443
          to_port     = 443
          ip_protocol = "tcp"
          cidr_ipv4   = ip
        }
      }
    ]...)
  }

  certificate_domain_name = var.certificate_domain_name
  route53_zone_id         = var.route53_zone_id

  tags = {
    Environment = "${var.env}"
    Terraform   = "true"
  }

  # EFS
  # enable_efs = true
  # efs = {
  #   mount_targets = {
  #     "${var.region}a" = {
  #       subnet_id = data.aws_subnets.subnet_ids_private.ids[0]
  #     }
  #     "${var.region}b" = {
  #       subnet_id = data.aws_subnets.subnet_ids_private.ids[1]
  #     }
  #     "${var.region}c" = {
  #       subnet_id = data.aws_subnets.subnet_ids_private.ids[2]
  #     }
  #   }
  # }
}
