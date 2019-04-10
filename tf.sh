#!/bin/bash
export AWS_PROFILE=saml
export AWS_REGION=us-west-2

ENV=$(aws iam list-account-aliases --output=text --query 'AccountAliases[0]' | sed 's/wiser-//')
echo "ENV=$ENV"

DATADOG_API_KEY=ac6e202b79385ebe44771bdb99b8d5f6 \
DATADOG_APP_KEY=74efabbd0a00910c1fca5a64221fec2dd9c866ba \
TF_VAR_env=$ENV \
terraform $@ 