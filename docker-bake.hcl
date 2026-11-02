variable "REGISTRY" { default = "docker.io" }
variable "NAMESPACE"  { default = "binarycodes" }
variable "IMAGE_NAME" { default = "github-runner" }

variable "GH_RUNNER_VERSION" { default = "2.338.2" }
variable "GH_RUNNER_CHECKSUM_X64"   { default = "sha256:baebf204307bac6193480852732f0aba2ae97b6c5597c244f4d5558390147c40" }
variable "GH_RUNNER_CHECKSUM_ARM64" { default = "sha256:670adb2f268fe21dcbb58b3db0e0aa9d5b3bddfe2c651481336e561ff86de945" }

variable "LOCAL" { default = false }

group "default" {
  targets = ["image"]
}

target "image" {
  context    = "."
  dockerfile = "Dockerfile"

  args = {
    RUNNER_VERSION = GH_RUNNER_VERSION
    RUNNER_CHECKSUM_X64 = GH_RUNNER_CHECKSUM_X64
    RUNNER_CHECKSUM_ARM64 = GH_RUNNER_CHECKSUM_ARM64
  }

  labels = {
    "org.opencontainers.image.title" = "homelab-github-runner"
    "org.opencontainers.image.description" = "Ephemeral GitHub Actions runner used in homelab"
    "org.opencontainers.image.version" = "${GH_RUNNER_VERSION}"
  }

  tags = [
    "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${GH_RUNNER_VERSION}",
    "${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:latest",
  ]

  platforms = LOCAL ? [] : ["linux/amd64", "linux/arm64"]
}
