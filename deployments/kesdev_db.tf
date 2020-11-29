resource "kubernetes_persistent_volume_claim" "pvc" {
  metadata {
    name = "kesdev-db"
  }
  spec {
    storage_class_name = "do-block-storage"
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = "kesdev-db"
  }
  spec {
    selector = {
      app = "kesdev-db"
    }
    port {
      port = 3306
    }
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name = "kesdev-db"
    labels = {
      app = "kesdev-db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "kesdev-db"
      }
    }

    template {
      metadata {
        labels = {
          app = "kesdev-db"
        }
      }

      spec {
        volume {
          name = "storage"
          persistent_volume_claim {
            claim_name = "kesdev-db"
          }
        }

        container {
          name  = "db"
          image = "mariadb:10.5.8"

          volume_mount {
            name       = "storage"
            mount_path = "/var/lib/mysql"
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = "superuser"
          }
          env {
            name  = "MYSQL_DATABASE"
            value = "ghost"
          }
          env {
            name  = "MYSQL_USER"
            value = "ghost"
          }
          env {
            name  = "MYSQL_PASSWORD"
            value = "ghost"
          }

          resources {
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits {
              cpu    = "1"
              memory = "1Gi"
            }
          }
        }
      }
    }
  }
}
