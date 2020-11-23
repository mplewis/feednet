data "digitalocean_kubernetes_versions" "versions" {}

resource "digitalocean_kubernetes_cluster" "feednet" {
  name         = "feednet"
  region       = "sfo3"
  version      = data.digitalocean_kubernetes_versions.versions.latest_version
  auto_upgrade = true

  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 6
  }
}

output "host" {
  value = digitalocean_kubernetes_cluster.feednet.endpoint
}
output "token" {
  value = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
}
output "cluster_ca_certificate" {
  value = base64decode(
    digitalocean_kubernetes_cluster.feednet.kube_config[0].cluster_ca_certificate
  )
}
