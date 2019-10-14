variable "access_key" {}
variable "secret_key" {}
variable "region" {}

provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region     = var.region
}

resource "aws_sns_topic" "new_orders" {
  name = "New-Orders"
}

resource "aws_sqs_queue" "orders_for_inventory" {
  name = "Orders-for-Inventory"
}

resource "aws_sqs_queue" "orders_for_analytics" {
  name = "Orders-for-Analytics"
}

resource "aws_sqs_queue_policy" "orders_queue_policy" {
  queue_url = aws_sqs_queue.orders_for_inventory.id
  depends_on = [aws_sqs_queue.orders_for_inventory]
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.orders_for_inventory.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.new_orders.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "analytics_queue_policy" {
  queue_url = aws_sqs_queue.orders_for_analytics.id
  depends_on = [aws_sqs_queue.orders_for_analytics]
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.orders_for_analytics.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.new_orders.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "inventory_sqs_target" {
  topic_arn  = aws_sns_topic.new_orders.arn
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.orders_for_inventory.arn
  depends_on = [aws_sqs_queue.orders_for_inventory]
}

resource "aws_sns_topic_subscription" "analytics_sqs_target" {
  topic_arn  = aws_sns_topic.new_orders.arn
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.orders_for_analytics.arn
  depends_on = [aws_sqs_queue.orders_for_analytics]
}

output "sns_topic_arn" {
  value = aws_sns_topic.new_orders.arn
}