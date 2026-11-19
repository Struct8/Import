resource "aws_flow_log" "flowlog-vpc-b" {
  vpc_id               = data.aws_vpc.wordpress-professional.id
  log_destination      = aws_s3_bucket.flowlogs-bucket.arn
  log_destination_type = "s3"
  log_format           = "$${version} $${vpc-id} $${subnet-id} $${interface-id} $${instance-id} $${srcaddr} $${dstaddr} $${pkt-srcaddr} $${pkt-dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${flow-direction} $${traffic-path} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${interface-type}"
  traffic_type         = "ALL"
  tags = {
    Name           = "flowlog-vpc-b"
    State          = "wp-flowlogs"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_s3_bucket_policy.aws_s3_bucket_policy_flowlogs-bucket_st_wp-flowlogs]
}
