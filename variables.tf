# This should be change once the production version is updated.
variable "ebmeds-version" {
  default = "dev"
}

variable "app" {
  default = "ebmeds"
}

variable "ebmeds-quay-secret" {
  default = "ebmeds-quay-secret"
}

variable "ebmeds-configuration" {
  default = "ebmeds-configuration"
}

variable "users-configuration" {
  default = "users-configuration"
}

variable "api-gateway-service-name" {
  default = "api-gateway"
}

variable "api-gateway-port" {
  default = 3001
}

variable "engine-service-name" {
  default = "engine"
}

variable "engine-container-port" {
  default = 3002
}

variable "master-data-service-name" {
  default = "master-data"
}

variable "master-data-port" {
  default = 3020
}

variable "replicas" {
  default = 1
}
