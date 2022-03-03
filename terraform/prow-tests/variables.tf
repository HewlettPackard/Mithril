variable "TAG" {
  default     = "latest"
  description = "TAG used to download the images from ECR repository"
}

variable "BUILD_TAG" {
  default     = "latest"
  description = "Build TAG from Jenkins Pipeline"
}

variable "HUB" {
  default     = "529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril/prow"
  description = "HUB used to download the images from ECR repository"
}

variable "ECR_REGION" {
  default     = "us-east-1"
  description = "ECR region specified to download the docker images"
}

variable "ARTIFACT_BUCKET_NAME" {
  default     = "mithril-artifacts"
  description = "S3 Bucket name for the Mithril Artifacts"
}

variable "AWS_PROFILE" {
  default     = "prow"
  description = "AWS profile used to grant access to AWS CLI API"
}

variable "EC2_AMI" {
  default     = "ami-09e67e426f25ce0d7"
  description = "Ubuntu 20.04 LTS AMI ID"
}

variable "EC2_INSTANCE_TYPE" {
  default     = "t2.xlarge"
  description = "EC2 Instance type created by terraform"
}

variable "EC2_KEY_PAIR" {
  default     = "mithril-integration-test"
  description = "AWS key pair name used to connect to the EC2 instance"
}

variable "VOLUME_SIZE" {
  default     = 50
  description = "Root block device volume size used by EC2 instance"
}

variable "USECASE" {
  default     = "simple-bookinfo"
  description = "Initial usecase"
}

variable "ISTIO_BRANCH" {
  default     = "release-1.10"
  description = "Istio branch to run unit tests"
}