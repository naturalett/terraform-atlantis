# Atlantis on AWS ECS with Datadog Integration


## Welcome to Our Atlantis GitHub Adventure!

Hey there! 👋 We're thrilled to share our journey of setting up [Atlantis](https://www.runatlantis.io/) on AWS ECS with a dash of magic—custom metrics integration using [Datadog](https://www.datadoghq.com/). Imagine automating your Infrastructure as Code (IaC) processes and making collaboration a breeze!

## What Makes This Project Awesome?

- **See Changes at a Glance**: Atlantis brings real-time status and history of infrastructure changes directly to your pull requests.
- **Teamwork Made Easy**: Initiate Terraform pull requests securely without the hassle of sharing credentials across your team.
- **Smarter Reviews**: Get essential Terraform Plan/Apply details right in your pull requests.

## Let's Dive into the Setup!

1. **Atlantis on ECS**: Spin up Atlantis on AWS ECS using Terraform. Here's a sneak peek of the setup:

    ```hcl
    module "atlantis" {
      source  = "terraform-aws-modules/atlantis/aws"
      name    = "atlantis"

      # ECS Container Definition
      atlantis = {
        environment = [
        ]
        secrets = [
        ]
      }
    }
    ```

2. **Datadog's Special Appearance**: Boost visibility by adding a Datadog sidecar container right alongside Atlantis.

    ```hcl
    module "atlantis" {
      source = "terraform-aws-modules/atlantis/aws"
      name   = "atlantis"

      # ECS Container Definition
      atlantis = {
        environment = [
        ]
        secrets = [
        ]
      }

      # ECS Service
      service = {
        container_definitions = {
          datadog-agent = {
            name   = "datadog-agent"
            image  = "gcr.io/datadoghq/agent:7.46.0"
            memory = "900"
            cpu    = "400"
            environment = [
              # Datadog configuration
            ]
            readonly_root_filesystem = false
          }
        }
      }
    }
    ```

3. **Prometheus and OpenMetrics Rockstars**: Collect metrics using Prometheus Autodiscovery.

    ```hcl
    # Datadog container labels
    docker_labels = {
      "com.datadoghq.ad.instances" : "[{\"openmetrics_endpoint\": \"http://%%host%%:4141/metrics\", \"namespace\": \"atlantis\", \"metrics\": [\"...\"]}]",
      "com.datadoghq.ad.check_names" : "[\"openmetrics\"]",
      "com.datadoghq.ad.init_configs" : "[{}]"
    }
    ```

4. **Secrets Guarded in the Shadows**: Safely store GitHub and Datadog tokens in AWS Secrets Manager. No secrets exposed here!

    ```hcl
    data "aws_secretsmanager_secret_version" "github_token" {
      secret_id = "/github/token"
    }

    data "aws_secretsmanager_secret_version" "datadog_api_key_plaintext" {
      secret_id = "/datadog/api_key_plaintext"
    }
    ```

5. **GitHub Webhook Awesomeness**: Set up webhooks for Atlantis to be able to create a pull request events.

    ```hcl
    resource "github_repository_webhook" "atlantis" {
      repository = "your_repository_name"

      configuration {
        url          = "${module.atlantis.url}/events"
        content_type = "application/json"
        insecure_ssl = false
        secret       = "your_random_webhook_secret"
      }

      events = ["issue_comment", "pull_request", "pull_request_review", "pull_request_review_comment"]
    }
    ```

6. **Pre-Workflow Showtime**: Define pre-workflow hooks to run scripts before the main act.

    ```yaml
    # server-atlantis.yaml
    version: 3

    projects:
      - name: terraform
        autoplan:
          enabled: true
    ```

## Custom Workflow - Behind the Scenes

Explore our complete custom workflow [here](https://github.com/naturalett/terraform-atlantis/blob/main/server-atlantis.yaml).


## Wrapping It Up

By bringing Atlantis to AWS ECS, we've not just upgraded our IaC game but also turned collaboration into an art. The secret sauce lies in the automation Atlantis brings to our infrastructure.


Thanks for joining our adventure! Got questions or want to share your thoughts? Reach out to us at [admin@top10devops.com](mailto:admin@top10devops.com). Happy coding! 🚀✨
