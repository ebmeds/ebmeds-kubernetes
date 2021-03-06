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
    command = "kubectl apply -f ./module/elastic/init/elastic-custom-resource-definition-1.0.0.yaml"
    interpreter = ["sh", "-c"]
  }
}

resource "kubernetes_persistent_volume" "elasticsearch-pv" {
  metadata {
    name = "elasticsearch-pv"
    labels = {
      app = var.app
      name = "elasticsearch-pv"
    }
  }
  spec {
    storage_class_name = "elasticsearch-standard"
    capacity = {
      storage = var.elasticsearch-storage-size
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      /******************************* W A R N I N G ********************************
      * REPLACE WITH A CORRECT PERSISTENT VOLUME TYPE: The hostPath is NOT SUITABLE *
      * for production and IT _MUST_ BE REPLACED with the persistent volume type    *
      * that is supported by your kubernetes cluster.                               *
      *******************************************************************************/
      host_path {
        path = "/mnt/elasticsearch-data"
      }
    }
    persistent_volume_reclaim_policy = "Retain"
  }
}

module "api-gateway" {
  source = "./module/ebmeds/api-gateway"

  app = var.app
  service-name = var.api-gateway-service-name
  image = "quay.io/duodecim/ebmeds-api-gateway:${var.ebmeds-version}"
  container-port = var.api-gateway-port
  node-port = var.api-gateway-node-port
  replicas = 2
  engine-health-check = "http://${var.engine-service-name}:${var.engine-container-port}/status"
  ebmeds-quay-secret = var.ebmeds-quay-secret
  ebmeds-configuration = var.ebmeds-configuration
  users-configuration = var.users-configuration
  timezone-city = var.timezone-city
  timezone-continent = var.timezone-continent
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
  timezone-city = var.timezone-city
  timezone-continent = var.timezone-continent
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
  timezone-city = var.timezone-city
  timezone-continent = var.timezone-continent
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
  timezone-city = var.timezone-city
  timezone-continent = var.timezone-continent
}

module "logstash" {
  source = "./module/elastic/logstash"

  app = var.app
  replicas = var.replicas
}
