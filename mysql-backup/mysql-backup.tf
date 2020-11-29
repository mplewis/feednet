variable "name" {
  type        = string
  description = "The name of the backup job"
}
variable "schedule" {
  type        = string
  description = "The crontab schedule for periodic backups"
}
variable "host" {
  type        = string
  description = "The MySQL database host"
}
variable "password" {
  type        = string
  description = "The password for the root superuser"
}

resource "kubernetes_cron_job" "mysql-backup" {
  metadata {
    name = "${var.name}-mysql-backup"
  }
  spec {
    schedule = var.schedule
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            restart_policy = "Never"
            container {
              name  = "mysql-backup"
              image = "databack/mysql-backup:a7f39c710fe48354a49d15f8fa575bb98f577c48"
              env {
                name  = "DB_SERVER"
                value = var.host
              }
              env {
                name  = "DB_USER"
                value = "root"
              }
              env {
                name  = "DB_PASS"
                value = var.password
              }
              env {
                name  = "DB_DUMP_TARGET"
                value = "s3://mplewis-db-backups/${var.name}"
              }
              env {
                name  = "AWS_DEFAULT_REGION"
                value = "us-west-2"
              }
              env {
                name = "AWS_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = "aws-s3-creds"
                    key  = "access-key-id"
                  }
                }
              }
              env {
                name = "AWS_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = "aws-s3-creds"
                    key  = "secret-access-key"
                  }
                }
              }
              env {
                name  = "RUN_ONCE"
                value = "true"
              }
            }
          }
        }
      }
    }
  }
}
