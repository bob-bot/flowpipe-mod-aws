pipeline "test_run_ec2_instance" {
  title       = "Test Run EC2 Instance"
  description = "Test the run_ec2_instances pipeline."

  tags = {
    folder = "Tests"
  }

  param "conn" {
    type        = connection.aws
    description = local.conn_param_description
    default     = connection.aws.default
  }

  param "region" {
    type        = string
    description = local.region_param_description
  }

  param "instance_type" {
    type        = string
    description = "The EC2 instance type (e.g., t2.micro)."
    default     = "t2.micro"
  }

  param "image_id" {
    type        = string
    description = "The ID of the Amazon Machine Image (AMI) to launch."
    default     = "ami-041feb57c611358bd"
  }

  step "pipeline" "run_ec2_instances" {
    pipeline = pipeline.run_ec2_instances
    args = {
      conn          = param.conn
      region        = param.region
      instance_type = param.instance_type
      image_id      = param.image_id
    }
  }

  step "pipeline" "describe_ec2_instances" {
    if       = !is_error(step.pipeline.run_ec2_instances)
    pipeline = pipeline.describe_ec2_instances
    args = {
      conn         = param.conn
      region       = param.region
      instance_ids = [step.pipeline.run_ec2_instances.output.instances[0].InstanceId]
    }

    # Ignore errors so we can delete
    error {
      ignore = true
    }
  }

  step "pipeline" "terminate_ec2_instances" {
    if = !is_error(step.pipeline.run_ec2_instances)

    # Don't run before we've had a chance to describe the instance
    depends_on = [step.pipeline.describe_ec2_instances]

    pipeline = pipeline.terminate_ec2_instances
    args = {
      conn         = param.conn
      region       = param.region
      instance_ids = [step.pipeline.run_ec2_instances.output.instances[0].InstanceId]
    }
  }

  output "created_instance_id" {
    description = "Instance used in the test."
    value       = step.pipeline.run_ec2_instances.output.instances[0].InstanceId
  }

  output "test_results" {
    description = "Test results for each step."
    value = {
      "run_ec2_instances"       = !is_error(step.pipeline.run_ec2_instances) ? "pass" : "fail: ${error_message(step.pipeline.run_ec2_instances)}"
      "describe_ec2_instances"  = !is_error(step.pipeline.describe_ec2_instances) ? "pass" : "fail: ${error_message(step.pipeline.describe_ec2_instances)}"
      "terminate_ec2_instances" = !is_error(step.pipeline.terminate_ec2_instances) ? "pass" : "fail: ${error_message(step.pipeline.terminate_ec2_instances)}"
    }
  }

}
