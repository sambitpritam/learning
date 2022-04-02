terraform {
  cloud {
    organization = "tc-aws-learning"

    workspaces {
      name = "test-terransible"
    }
  }
}