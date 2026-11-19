variable "ip" {
  type        = string
  default     = "10.1.1.1"
  description = "ip privado"
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
