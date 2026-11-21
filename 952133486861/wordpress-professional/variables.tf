variable "alarm_email" {
  type        = string
  default     = "rbpmconsulting@gmail.com"
  description = "Address that receives the CloudWatch alarms of the site. AWS sends a confirmation message to it after the apply, and alarms arrive only after the subscription is confirmed."
}

variable "allow_data_loss" {
  type        = bool
  default     = true
  description = "When true, a destroy deletes the Aurora cluster without a final snapshot and empties the media bucket. Use false in production."
}

variable "app_min_instances" {
  type        = number
  default     = 1
  description = "Minimum number of EC2 instances of the WordPress cluster. Use 2 in production, so the tasks run in both Availability Zones; 1 costs less in a test."
}

variable "nat-instance" {
  type        = string
  default     = "t4g.nano"
  description = "instancia para nat"
}

variable "volume-type2" {
  type    = string
  default = "gp2"
}
