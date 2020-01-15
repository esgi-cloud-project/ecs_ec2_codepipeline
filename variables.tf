variable "GITHUB_ACCESS_TOKEN" {
    type= string
    description = "Git hub acces token"
}

variable "az_count" {
  description = "Number of AZs to cover in a given region"
  default     = "2"
}