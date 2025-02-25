resource "sdm_node" "this" {
  proxy_cluster {
    name    = "${var.name}-proxy"
    address = "${aws_lb.this.dns_name}:${var.traffic_port}"
    tags    = var.tags
  }
}

resource "sdm_proxy_cluster_key" "this" {
  proxy_cluster_id = sdm_node.this.id
}
