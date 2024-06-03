# Only required for production. The test/staging environments share produciton's build artifacts.

# This user is used by the common-payments-module repo's CI workflows
# One of a kind
# tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "cpm_ci" {
  name = "cpm-ci"

  lifecycle {
    ignore_changes = [tags, tags_all] # AWS uses tags for access key descriptions
  }
}

# This user is used by the delta repo's CI workflows
# One of a kind
# tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "delta_ci" {
  name = "delta_ci"

  lifecycle {
    ignore_changes = [tags, tags_all] # AWS uses tags for access key descriptions
  }
}

# tfsec:ignore:aws-iam-no-user-attached-policies
resource "aws_iam_user" "delta_auth_ci" {
  name = "delta-auth-ci"

  lifecycle {
    ignore_changes = [tags, tags_all] # AWS uses tags for access key descriptions
  }
}

locals {
  repositories = {
    "cpm" = {
      repo_name = "cpm",
      push_user = aws_iam_user.cpm_ci.name
    },
    "delta_api" = {
      repo_name = "delta-api",
      push_user = aws_iam_user.delta_ci.name
    },
    "delta_fo_to_pdf" = {
      repo_name = "delta-fo-to-pdf",
      push_user = aws_iam_user.delta_ci.name
    },
    "keycloak" = {
      repo_name = "keycloak",
      push_user = aws_iam_user.delta_ci.name
    },
    "auth_service" = {
      repo_name = "delta-auth-service",
      push_user = aws_iam_user.delta_auth_ci.name
    },
  }
}

module "ecr" {
  for_each  = local.repositories
  source    = "../modules/ecr_repository"
  kms_alias = "alias/${each.key}-ecr"
  repo_name = each.value["repo_name"]
  push_user = each.value["push_user"]
}
