
resource "kubernetes_deployment" "kesdev" {
  metadata {
    name = "kesdev"
    labels = {
      app = "kesdev"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "kesdev"
      }
    }

    template {
      metadata {
        labels = {
          app = "kesdev"
        }
      }

      spec {
        volume {
          name = "ghost-data"
          empty_dir {}
        }

        container {
          name  = "ghost"
          image = "ghost:3.38.2"
          # don't let Ghost default entrypoint clobber content/ mount,
          # and don't let this container start before s3fs does
          command = ["bash", "-c", "ls content/themes && node current/index.js"]

          env {
            name  = "url"
            value = "https://kesdev.fdnt.me"
          }
          env {
            name  = "database__client"
            value = "sqlite3"
          }
          env {
            name  = "database__connection__filename"
            value = "/var/lib/ghost/content/ghost.db"
          }

          resources {
            requests {
              cpu    = "100m"
              memory = "300Mi"
            }
            limits {
              cpu    = "1"
              memory = "1Gi"
            }
          }

          volume_mount {
            name              = "ghost-data"
            mount_path        = "/var/lib/ghost/content"
            mount_propagation = "HostToContainer"
          }
        }

        container {
          name  = "s3fs"
          image = "efrecon/s3fs:latest"

          volume_mount {
            name              = "ghost-data"
            mount_path        = "/opt/s3fs/bucket"
            mount_propagation = "Bidirectional"
          }

          env {
            name  = "AWS_S3_BUCKET"
            value = "kesdev"
          }
          env {
            name = "AWS_S3_ACCESS_KEY_ID"
            value_from {
              secret_key_ref {
                name = "aws-s3-creds"
                key  = "access-key-id"
              }
            }
          }
          env {
            name = "AWS_S3_SECRET_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = "aws-s3-creds"
                key  = "secret-access-key"
              }
            }
          }

          resources {
            requests {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits {
              cpu    = "1"
              memory = "256Mi"
            }
          }

          security_context {
            privileged = true
            capabilities {
              add = ["SYS_ADMIN"]
            }
          }
        }
      }
    }
  }
}
