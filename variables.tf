variable "public_key" {
  type = string
}

variable "instance_type" {
  type = string
  validation {
    condition     = can(regex("^t2.micro$", var.instance_type))
    error_message = "The instance type should be t2.micro."
  }
}

variable "cidr_ip" {
  type = string
}

variable "ami_id" {
  type = string
}