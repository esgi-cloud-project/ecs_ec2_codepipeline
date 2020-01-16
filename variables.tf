variable "GITHUB_ACCESS_TOKEN" {
    type= string
    description = "Git hub acces token"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 3000
}

variable "vpc" {
  description = "VPC object"
}

variable "public_subnet_depends_on" {
  type    = any
  default = null
}

variable "sqs_id" {
    type = string
    description = "The sqs event queue use by the serverless function"
}

variable "sqs_arn" {
    type = string
    description = "The sqs event queue use by the serverless function"
}