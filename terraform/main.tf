module "ccm" {
  source              = "github.com/rssnyder/terraform-aws-harness-ccm.git"
  external_id         = "harness:891928451355:wlgELJ0TTre5aZhzpt8gVA"
  enable_events       = true
  enable_optimization = true
  prefix              = "tf-"
}
