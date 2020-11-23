resource "kubernetes_deployment" "podinfo" {
  metadata {
    name = "podinfo"
    labels = {
      app = "podinfo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "podinfo"
      }
    }

    template {
      metadata {
        labels = {
          app = "podinfo"
        }
      }

      spec {
        container {
          image = "stefanprodan/podinfo:latest"
          name  = "podinfo"

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
