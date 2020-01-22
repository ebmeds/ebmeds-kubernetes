variable "app" {}
variable "service-name" {
  default = "engine"
}
variable "timezone-continent" {}
variable "timezone-city" {}
variable "master-data-service-name" {}
variable "engine-image" {}
variable "master-data-image" {}
variable "container-port" {}
variable "master-data-port" {}
variable "replicas" {}
variable "ebmeds-configuration" {}
variable "ebmeds-quay-secret" {}
variable "init-helper-command" {
  default = ["echo"]
}
variable "health-check-path" {
  default = "/status"
}

resource "kubernetes_deployment" "engine-deployment" {
  metadata {
    name = var.service-name
    labels = {
      app = var.app
      name = var.service-name
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
          command = var.init-helper-command
        }
        container {
          name = var.master-data-service-name
          image = var.master-data-image
          image_pull_policy = "Always"
          command = ["/bin/sh"]
          args = ["-c", "cp -r /master-data/staging /master-data/init/ && cp -r /master-data/versions /master-data/init/ && cp -r /master-data/version-mapping /master-data/init/ && npm start"]
          volume_mount {
            name = "master-data-volume"
            mount_path = "/master-data/init"
          }
          port {
            container_port = var.master-data-port
          }
          readiness_probe {
            http_get {
              path = var.health-check-path
              port = var.master-data-port
            }
            initial_delay_seconds = 60
            period_seconds = 10
            timeout_seconds = 5
          }
          liveness_probe {
            http_get {
              path = var.health-check-path
              port = var.master-data-port
            }
            initial_delay_seconds = 180
            period_seconds = 10
            timeout_seconds = 5
          }
          env_from {
            config_map_ref {
              name = var.ebmeds-configuration
            }
          }
        }
        container {
          name = var.service-name
          image = var.engine-image
          image_pull_policy = "Always"
          port {
            container_port = var.container-port
          }
          readiness_probe {
            http_get {
              path = var.health-check-path
              port = var.container-port
            }
            initial_delay_seconds = 60
            period_seconds = 10
            timeout_seconds = 5
          }
          liveness_probe {
            http_get {
              path = var.health-check-path
              port = var.container-port
            }
            initial_delay_seconds = 180
            period_seconds = 10
            timeout_seconds = 5
          }
          env_from {
            config_map_ref {
              name = var.ebmeds-configuration
            }
          }
          volume_mount {
            name = "master-data-volume"
            mount_path = "/app/master-data/staging"
            sub_path = "staging"
            read_only = true
          }
          volume_mount {
            name = "master-data-volume"
            mount_path = "/app/master-data/version-mapping"
            sub_path = "version-mapping"
            read_only = true
          }
          volume_mount {
            name = "master-data-volume"
            mount_path = "/app/master-data/versions"
            sub_path = "versions"
            read_only = true
          }
          volume_mount {
            name = "tz-config"
            mount_path = "/etc/localtime"
          }
          resources {
            requests {
              cpu = "500m"
              memory = "500Mi"
            }
            limits {
              cpu = "1"
              memory = "1Gi"
            }
          }
        }
        
          volume {
            name = "master-data-volume"
            empty_dir {}
          }
          volume {
            name = "tz-config"
            host_path {
              path = "/usr/share/zoneinfo/${var.timezone-continent}/${var.timezone-city}"
            }
          }
        
        image_pull_secrets {
          name = var.ebmeds-quay-secret
        }
        security_context {}
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

resource "kubernetes_service" "engine-service" {
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
    }
    type = "ClusterIP"
  }
}
