resource "kubernetes_deployment" "pokemon-emerald" {
  metadata {
    name = "pokemon-emerald"
    labels = {
      app = "pokemon-emerald"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "pokemon-emerald"
      }
    }

    template {
      metadata {
        labels = {
          app = "pokemon-emerald"
        }
      }

      spec {
        volume {
          name = "roms"
          empty_dir {}
        }
        volume {
          name = "saves"
          empty_dir {}
        }

        container {
          name  = "cuttlegame"
          image = "cuttlegame:1.0.0"

          env {
            name  = "CORE"
            value = "vbam"
          }
          env {
            name  = "ROM"
            value = "pokemon_emerald.gba"
          }
          env {
            name = "PASSWORD"
            value_from {
              secret_key_ref {
                name = "cuttlegame-password"
                key  = "password"
              }
            }
          }

          volume_mount {
            name              = "roms"
            mount_path        = "/roms"
            mount_propagation = "HostToContainer"
          }
          volume_mount {
            name              = "saves"
            mount_path        = "/saves"
            mount_propagation = "HostToContainer"
          }

          resources {
            requests {
              cpu    = "100m"
              memory = "1Gi"
            }
            limits {
              cpu    = "1"
              memory = "2Gi"
            }
          }
        }

        container {
          name  = "s3fs"
          image = "efrecon/s3fs:latest"

          volume_mount {
            name              = "roms"
            mount_path        = "/opt/s3fs/bucket/roms"
            mount_propagation = "Bidirectional"
          }

          volume_mount {
            name              = "saves"
            mount_path        = "/opt/s3fs/bucket/saves"
            mount_propagation = "Bidirectional"
          }

          env {
            name  = "AWS_S3_BUCKET"
            value = "cuttlegame"
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
