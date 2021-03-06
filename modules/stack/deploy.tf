resource "aws_s3_bucket" "explorer_releases" {
  bucket = "${var.prefix}-explorer-codedeploy-releases"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_codedeploy_app" "explorer" {
  name = "${var.prefix}-explorer"
}

resource "aws_codedeploy_deployment_group" "explorer" {
  count                 = "${length(var.chains)}"
  app_name              = "${aws_codedeploy_app.explorer.name}"
  deployment_group_name = "${var.prefix}-explorer-dg${count.index}"
  service_role_arn      = "${aws_iam_role.deployer.arn}"
  autoscaling_groups    = ["${aws_autoscaling_group.explorer.*.id[count.index]}"]

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  load_balancer_info {
    elb_info {
      name = "${var.prefix}-explorer-${element(keys(var.chains),count.index)}-elb"
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 30
    }

    green_fleet_provisioning_option {
      action = "DISCOVER_EXISTING"
    }

    terminate_blue_instances_on_deployment_success {
      action = "KEEP_ALIVE"
    }
  }
}
