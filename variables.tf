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

variable "timezone-continent" {
  default = "Europe"
}

variable "timezone-city" {
  default = "Helsinki"
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

variable "caregap-port" {
  default = 3006
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

variable "elasticsearch-storage-size" {
  default = "10Gi" // Please increase this to 500Gi in larger environments
}
