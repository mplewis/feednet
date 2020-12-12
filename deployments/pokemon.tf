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
          name = "content"
          empty_dir {}
        }
        volume {
          name = "config"
          config_map {
            name = "pokemon-emerald"
          }
        }

        container {
          name  = "cuttlegame"
          image = "mplewis/cuttlegame:1.2.1"

          env {
            name  = "CORE"
            value = "vbam"
          }
          env {
            name  = "ROM"
            value = "/content/roms/pokemon_emerald.gba"
          }
          env {
            name  = "CONFIG"
            value = "/config/retroarch.cfg"
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
            name              = "content"
            mount_path        = "/content"
            mount_propagation = "HostToContainer"
          }
          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          resources {
            requests {
              cpu    = "300m"
              memory = "128Mi"
            }
            limits {
              cpu    = "1"
              memory = "256Mi"
            }
          }
        }

        container {
          name  = "s3fs"
          image = "efrecon/s3fs:latest"

          volume_mount {
            name              = "content"
            mount_path        = "/opt/s3fs/bucket"
            mount_propagation = "Bidirectional"
          }

          env {
            name  = "AWS_S3_BUCKET"
            value = "cuttlegames"
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

resource "kubernetes_config_map" "example" {
  metadata {
    name = "pokemon-emerald"
  }
  data = {
    "retroarch.cfg" = "savefile_directory = /content/saves\nsavestate_directory = /content/saves"
  }
}
