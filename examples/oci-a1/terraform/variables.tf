variable "tenancy_ocid" {
  type        = string
  description = "OCIテナンシーのOCID"
}

variable "user_ocid" {
  type        = string
  description = "OCIユーザーのOCID"
}

variable "fingerprint" {
  type        = string
  description = "APIキーのフィンガープリント"
}

variable "private_key_path" {
  type        = string
  description = "秘密鍵のパス"
}

variable "region" {
  type        = string
  description = "使用するOCIリージョン"
}

variable "compartment_id" {
  type        = string
  description = "コンパートメントのOCID"
}

variable "availability_domain" {
  type        = string
  description = "可用性ドメイン名"
}

variable "subnet_id" {
  type        = string
  description = "サブネットのOCID"
}

variable "image_id" {
  type        = string
  description = "使用するイメージのOCID"
}