variable "REGISTRY" { default = "docker.io" }
variable "NAMESPACE"  { default = "binarycodes" }
variable "IMAGE_NAME" { default = "github-runner" }

variable "GH_RUNNER_VERSION" { default = "2.333.1" }
variable "GH_RUNNER_CHECKSUM" { default = "18f8f68ed1892854ff2ab1bab4fcaa2f5abeedc98093b6cb13638991725cab74" }

variable "LOCAL" { default = false }

group "default" {
  targets = ["image"]
}

target "image" {
  context    = "."
  dockerfile = "Dockerfile"

  args = {
    RUNNER_VERSION = GH_RUNNER_VERSION
    RUNNER_CHECKSUM = GH_RUNNER_CHECKSUM
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
