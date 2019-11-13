provider "kubernetes" {
  version = "~> 1.7"
}

resource "kubernetes_secret" "ebmeds-quay-secret" {
  metadata {
    name = var.ebmeds-quay-secret
    labels = {
      app = var.app
      name = var.ebmeds-quay-secret
    }
  }
  data = {
    ".dockerconfigjson" = file(pathexpand("~/.docker/config.json"))
  }
  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_config_map" "users-configuration" {
  metadata {
    name = var.users-configuration
    labels = {
      app = var.app
      name = var.users-configuration
    }
  }
  data = {
    "users.json" = file("${path.module}/resource/users.json")
  }
}

resource "null_resource" "elastic-kubernetes-resource-definiton" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://download.elastic.co/downloads/eck/1.0.0-beta1/all-in-one.yaml"
    interpreter = ["sh", "-c"]
  }
}

module "api-gateway" {
  source = "./module/ebmeds/api-gateway"

  app = var.app
  service-name = var.api-gateway-service-name
  image = "quay.io/duodecim/ebmeds-api-gateway:${var.ebmeds-version}"
  container-port = var.api-gateway-port
  replicas = 2
  engine-health-check = "http://${var.engine-service-name}:${var.engine-container-port}/status"
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
  users-configuration = var.users-configuration
}

module "engine" {
  source = "./module/ebmeds/engine"

  app = var.app
  service-name = var.engine-service-name
  master-data-service-name = var.master-data-service-name
  engine-image = "quay.io/duodecim/ebmeds-engine:${var.ebmeds-version}"
  master-data-image = "quay.io/duodecim/ebmeds-master-data:latest"
  container-port = var.engine-container-port
  master-data-port = var.master-data-port
  replicas = var.replicas
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
}

module "cmr" {
  source = "./module/ebmeds/general"

  app = var.app
  service-name = "cmr"
  image = "quay.io/duodecim/ebmeds-cmr:${var.ebmeds-version}"
  container-port = 3003
  replicas = var.replicas
  api-gateway-health-check = "http://${var.api-gateway-service-name}:${var.api-gateway-port}/status"
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
}

module "dsv" {
  source = "./module/ebmeds/general"

  app = var.app
  service-name = "dsv"
  image = "quay.io/duodecim/ebmeds-diagnosis-specific-view:${var.ebmeds-version}"
  container-port = 3010
  replicas = var.replicas
  api-gateway-health-check = "http://${var.api-gateway-service-name}:${var.api-gateway-port}/status"
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
}

module "caregap" {
  source = "./module/ebmeds/general"

  app = var.app
  service-name = "caregap"
  image = "quay.io/duodecim/ebmeds-caregap:${var.ebmeds-version}"
  container-port = 3006
  replicas = var.replicas
  api-gateway-health-check = "http://${var.api-gateway-service-name}:${var.api-gateway-port}/status"
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
}
