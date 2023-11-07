pipeline "create_iam_instance_profile" {
  title       = "Create Instance Profile"
  description = "Creates a new instance profile."

  param "region" {
    type        = string
    description = local.region_param_description
    default     = var.region
  }

  param "access_key_id" {
    type        = string
    description = local.access_key_id_param_description
    default     = var.access_key_id
  }

  param "secret_access_key" {
    type        = string
    description = local.secret_access_key_param_description
    default     = var.secret_access_key
  }

  param "instance_profile_name" {
    type        = string
    description = "The name of the instance profile to create."
  }

  step "container" "create_iam_instance_profile" {
    image = "amazon/aws-cli"
    cmd = [
      "iam", "create-instance-profile",
      "--instance-profile-name", param.instance_profile_name,
    ]

    env = {
      AWS_REGION            = param.region
      AWS_ACCESS_KEY_ID     = param.access_key_id
      AWS_SECRET_ACCESS_KEY = param.secret_access_key
    }
  }

  output "stdout" {
    description = "The standard output stream from the AWS CLI."
    value = jsondecode(step.container.create_iam_instance_profile.stdout)
  }

   output "stderr" {
    description = "The standard error stream from the AWS CLI."
    value = step.container.create_iam_instance_profile.stderr
  }
}