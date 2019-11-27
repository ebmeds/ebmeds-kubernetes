variable "app" {}
variable "service-name" {
  default = "logstash"
}
variable "elastic-version" {
  default = "7.4.2"
}
variable "ebmeds-log-port" {
  default = 5000
}
variable "ebmeds-reminder-port" {
  default = 5001
}
variable "ebmeds-request-port" {
  default = 5005
}
variable "replicas" {}
variable "logstash-configuration-volume" {
  default = "logstash-configuration-volume"
}
variable "logstash-configurations" {
  default = "logstash-configurations"
}

resource "kubernetes_config_map" "logstash-configurations" {
  metadata {
    name = var.logstash-configurations
    labels = {
      app = var.app
      name = var.service-name
    }
  }
  data = {
    "logstash.yml" = file("${path.module}/config/logstash.yml")
    "pipelines.yml" = file("${path.module}/config/pipelines.yml")
    "ebmeds-log.conf" = file("${path.module}/pipeline/ebmeds-log.conf")
    "ebmeds-reminder.conf" = file("${path.module}/pipeline/ebmeds-reminder.conf")
    "ebmeds-request.conf" = file("${path.module}/pipeline/ebmeds-request.conf")
    "flat-source.rb" = file("${path.module}/ruby/flat-source.rb")
    "elasticsearch-es-http-certs-public.cer" = file("${path.module}/pipeline/elasticsearch-es-http-certs-public.cer")
  }
}

resource "kubernetes_deployment" "logstash-deployment" {
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
        container {
          name = var.service-name
          image = "docker.elastic.co/logstash/logstash:${var.elastic-version}"
          port {
            container_port = var.ebmeds-log-port
            name = "ebmeds-log"
          }
          port {
            container_port = var.ebmeds-reminder-port
            name = "ebmeds-reminder"
          }
          port {
            container_port = var.ebmeds-request-port
            name = "ebmeds-request"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/config/logstash.yml"
            name = var.logstash-configuration-volume
            sub_path = "logstash.yml"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/config/pipelines.yml"
            name = var.logstash-configuration-volume
            sub_path = "pipelines.yml"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/pipeline/ebmeds-log.conf"
            name = var.logstash-configuration-volume
            sub_path = "ebmeds-log.conf"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/pipeline/ebmeds-reminder.conf"
            name = var.logstash-configuration-volume
            sub_path = "ebmeds-reminder.conf"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/pipeline/ebmeds-request.conf"
            name = var.logstash-configuration-volume
            sub_path = "ebmeds-request.conf"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/ruby/flat-source.rb"
            name = var.logstash-configuration-volume
            sub_path = "flat-source.rb"
          }
          volume_mount {
            mount_path = "/usr/share/logstash/pipeline/elasticsearch-es-http-certs-public.cer"
            name = var.logstash-configuration-volume
            sub_path = "elasticsearch-es-http-certs-public.cer"
          }
        }
        volume {
          name = var.logstash-configuration-volume
          config_map {
            name = var.logstash-configurations
          }
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

resource "kubernetes_service" "logstash-service" {
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
      port = var.ebmeds-log-port
      target_port = var.ebmeds-log-port
      name = "ebmeds-log"
    }
    port {
      port = var.ebmeds-reminder-port
      target_port = var.ebmeds-reminder-port
      name = "ebmeds-reminder"
    }
    port {
      port = var.ebmeds-request-port
      target_port = var.ebmeds-request-port
      name = "ebmeds-request"
    }
    type = "ClusterIP"
  }
}
