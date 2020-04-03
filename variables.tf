variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "namespace" {
  type        = string
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
  default     = ""
}

variable "stage" {
  type        = string
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
  default     = ""
}

variable "name" {
  type        = string
  description = "Solution cluster name, e.g. 'main'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `1`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit`,`XYZ`)"
}

variable "description" {
  type        = string
  default     = ""
  description = "Elastic Beanstalk Application description"
}

variable "min_size" {
  description = "Minimum number of RabbitMQ nodes"
  default     = 2
}

variable "desired_size" {
  description = "Desired number of RabbitMQ nodes"
  default     = 2
}

variable "max_size" {
  description = "Maximum number of RabbitMQ nodes"
  default     = 2
}

variable "ec2_subnet_ids" {
  description = "Subnets for RabbitMQ nodes"
  type        = list(string)
}

variable "elb_subnet_ids" {
  description = "Subnets for ELB"
  type        = list(string)
}

variable "nodes_security_group_ids" {
  type    = list(string)
  default = null
}

variable "elb_security_group_ids" {
  type    = list(string)
  default = null
}

variable "instance_type" {
  default = "t3.small"
}

variable "instance_volume_type" {
  default = "gp2"
}

variable "instance_volume_size" {
  default = "0"
}

variable "instance_volume_iops" {
  default = "0"
}

variable "fallback_ondemand_instance_type" {
  default     = "t2.small"
  description = "The fallback instance type if desired is not available"
}

variable "ondemand_base_capacity" {
  default     = 2
  description = "Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances"
}

variable "ondemand_instance_type" {
  default     = "t3.small"
  description = "The desired on-demand instance type"
}

variable "ondemand_percentage_above_base_capacity" {
  default     = 100
  description = "Percentage split between on-demand and Spot instances above the base on-demand capacity"
}

variable "ssh_key_name" {
  default = null
}
