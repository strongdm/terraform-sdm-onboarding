output "strongdm_gateway_ips" {
  value       = module.sdm.sdm_gateway_ips != null ? module.sdm.sdm_gateway_ips : "no strongdm gateways created"
  description = "The IP addresses assigned to your strongDM gateways"
}
