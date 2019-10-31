variable "app" {}
variable "service-name" {}
variable "image" {}
variable "container-port" {}
variable "replicas" {}

variable "ebmeds-configuration" {}
variable "ebmeds-quay-secret" {}
variable "users-configuration" {}
variable "engine-health-check" {}
variable "health-check-path" {
  default = "/status"
}

resource "kubernetes_deployment" "api-gateway-deployment" {
  metadata {
    name = var.service-name
    labels = {
      app = var.app
      name = "${var.service-name}-deployment"
    }
  }
  spec {
    template {
      metadata {
        name = var.service-name
        labels = {
          app = var.app
          name = var.service-name
        }
      }
      spec {
        init_container {
          name = "init-helper"
          image = "busybox"
          command = ["sh", "-c", "until wget -O- ${var.engine-health-check}; do echo waiting for engine; sleep 5; done"]
        }
        container {
          name = var.service-name
          image = var.image
          port {
            container_port = var.container-port
          }
          readiness_probe {
            http_get {
              path = var.health-check-path
              port = var.container-port
            }
            initial_delay_seconds = 15
            period_seconds = 10
            timeout_seconds = 5
          }
          liveness_probe {
            http_get {
              path = var.health-check-path
              port = var.container-port
            }
            initial_delay_seconds = 60
            period_seconds = 10
            timeout_seconds = 5
          }
          env_from {
            config_map_ref {
              name = var.ebmeds-configuration
            }
          }
          volume_mount {
            mount_path = "/app/resource/users.json"
            name = "users-volume"
            sub_path = "users.json"
          }
        }
        volume {
          name = "users-volume"
          config_map {
            name = "users-configuration"
          }
        }
        image_pull_secrets {
          name = var.ebmeds-quay-secret
        }
      }
    }
    replicas = var.replicas
    selector {
      match_labels = {
        app = var.app
        name = var.service-name
      }
    }
  }
}

resource "kubernetes_service" "api-gateway-service" {
  metadata {
    name = var.service-name
    labels = {
      app = var.app
      name = "${var.service-name}-service"
    }
  }
  spec {
    selector = {
      app = var.app
      name = var.service-name
    }
    port {
      port = var.container-port
      target_port = var.container-port
      node_port = var.container-port
    }
    type = "NodePort"
  }
}

output "api-gateway-ip" {
  value = kubernetes_service.api-gateway-service
}
