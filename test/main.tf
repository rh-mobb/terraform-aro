variable "subscription_id" {}

module "test" {
  source = "../"

  subscription_id = var.subscription_id
  cluster_name    = "test-cluster"
  domain          = "example.com"
}
