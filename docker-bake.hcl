variable "REGISTRY" { default = "docker.io" }
variable "NAMESPACE"  { default = "binarycodes" }
variable "IMAGE_NAME" { default = "github-runner" }

variable "GH_RUNNER_VERSION" { default = "2.338.1" }
variable "GH_RUNNER_CHECKSUM_X64"   { default = "sha256:08e9ccb3604d2462c24b5e33604dc30810296ca15cc65f23cffd4317eb144c37" }
variable "GH_RUNNER_CHECKSUM_ARM64" { default = "sha256:475e0c149fd3b611610127b9664ba5bacf5c6928795cc448ab520bb5f324bede" }

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
