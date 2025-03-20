#!/bin/bash

# OCI認証情報
export TF_VAR_tenancy_ocid="your-tenancy-ocid"
export TF_VAR_user_ocid="your-user-ocid"
export TF_VAR_fingerprint="your-fingerprint"
export TF_VAR_private_key_path="~/.oci/private.pem"
export TF_VAR_region="ap-tokyo-1"  # 使用するリージョン

# OCI設定
export TF_VAR_compartment_id="your-compartment-id"
export TF_VAR_availability_domain="your-availability-domain"
export TF_VAR_subnet_id="your-subnet-id"
export TF_VAR_image_id="your-image-id"

# 通知設定
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/your-webhook-url"
export SLACK_WEBHOOK="https://hooks.slack.com/services/your-slack-webhook"

# 使用方法：
# source env-vars.sh
# docker-compose up -d