variable "REGISTRY" { default = "docker.io" }
variable "NAMESPACE"  { default = "binarycodes" }
variable "IMAGE_NAME" { default = "github-runner" }

variable "GH_RUNNER_VERSION" { default = "2.338.0" }
variable "GH_RUNNER_CHECKSUM_X64"   { default = "sha256:af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32" }
variable "GH_RUNNER_CHECKSUM_ARM64" { default = "sha256:628b4a7258487b80c1d3c221095a7ded349f5ae0175fd3dfab708d07428f041b" }

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
