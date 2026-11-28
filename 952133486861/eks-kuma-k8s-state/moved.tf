moved {
  from = aws_security_group.uptime_kuma_pod_sg
  to   = aws_security_group.kuma_uptime_kuma_pod_sg
}

moved {
  from = aws_security_group_rule.rule_cluster_to_uptime_kuma_pod_sg_tcp_3001
  to   = aws_security_group_rule.rule_cluster_to_kuma_uptime_kuma_pod_sg_tcp_3001
}

moved {
  from = aws_security_group_rule.rule_uptime_kuma_pod_sg_to_cluster_apiserver
  to   = aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_apiserver
}

moved {
  from = aws_security_group_rule.rule_uptime_kuma_pod_sg_to_cluster_dns_tcp
  to   = aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_tcp
}

moved {
  from = aws_security_group_rule.rule_uptime_kuma_pod_sg_to_cluster_dns_udp
  to   = aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_cluster_dns_udp
}

moved {
  from = aws_security_group_rule.rule_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306
  to   = aws_security_group_rule.rule_kuma_uptime_kuma_pod_sg_to_db_instance_kuma_db_group_tcp_3306
}
