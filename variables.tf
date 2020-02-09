variable "code_pipeline_source_conf" {
    type= object({
      OAuthToken = string,
      Owner = string,
      Repo = string,
      Branch = string
    })
    description = "Code pipeline source object conf please refer to aws documentation for a valid one"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  default     = 3000
}

variable "vpc" {
  description = "VPC object"
}

variable "private_subnet" {
  description = "VPC private subnet"
}

variable "public_subnet" {
  description = "VPC public subnet"
}

variable "availability_zone" {
  description = "Availability zone"
}


variable "prefix" {
  description = "Prefix name for all ressources"
}

variable "buildspec_path" {
  description = "Path for the build spec"
}

variable "task_definition_path" {
  description = "Path for the task definition"
}

variable "public_subnet_depends_on" {
  type    = any
  default = null
}

# variable "sqs_id" {
#     type = string
#     description = "The sqs event queue use by the serverless function"
# }

# variable "sqs_arn" {
#     type = string
#     description = "The sqs event queue use by the serverless function"
# }

variable "container_env" {
  type = map
  default = {}
}
