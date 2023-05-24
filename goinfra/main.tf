data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "setup" {
  template = file("./goinfra/setup.tpl")
}

# Create a security group allowing inbound SSH and HTTP access
resource "aws_security_group" "general_sg" {
  name = "general_sg"

  # Inbound rule for SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound rule for HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rule allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Provision the ec2 instance for SERVER
resource "aws_instance" "goserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.general_sg.id]
  user_data              = data.template_file.setup.rendered

  tags = {
    "Name" = "goserver"
  }
}

# Provision the ec2 instance for CLIENT
resource "aws_instance" "goclient" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.general_sg.id]
  user_data              = data.template_file.setup.rendered

  tags = {
    "Name" = "goclient"
  }
}

# Create an S3 bucket
resource "aws_s3_bucket" "gobucket" {
  bucket        = "gobucket"
  acl = 
  force_destroy = true
}

# Configure the S3 bucket policy to allow public read access
resource "aws_s3_bucket_policy" "gobucket_policy" {
  bucket = aws_s3_bucket.gobucket.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.gobucket.id}/*"
      ]
    }
  ]
}
EOF
}

# Upload the assets folder to the S3 bucket
resource "aws_s3_bucket_object" "assets" {
  bucket    = aws_s3_bucket.gobucket.id
  key       = "assets/"
  provisioner "file" {
    source      = "./goinfra/goassets"
    destination = "${aws_s3_bucket.gobucket.id}/goassets"
  }
}

# Create a CloudWatch alarm for each server instance
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  count               = length(["${aws_instance.goserver.id}", "${aws_instance.goclient.id}"])
  alarm_name          = "CPUUtilizationAlarm_${["${aws_instance.goserver.id}", "${aws_instance.goclient.id}"][count.index]}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "Alarm when CPU utilization exceeds 70%"
  alarm_actions       = ["arn:aws:sns:us-east-1:${var.aws_account_id}:HighCPUUtilizationNotification"] # Update with desired SNS topic ARN
  alarm_enabled       = true

  dimensions = {
    InstanceId = "${["${aws_instance.goserver.id}", "${aws_instance.goclient.id}"][count.index]}"
  }
}

output "goserver_pub_ip" {
  value     = aws_instance.goserver.public_ip
  sensitive = true
}

output "goclient_pub_ip" {
  value     = aws_instance.goclient.public_ip
  sensitive = true
}
