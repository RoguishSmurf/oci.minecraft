#! /bin/bash

namespace=$(oci os ns get | jq -r .data)
oci os bucket create --name terraform_state --namespace $namespace --compartment-id $OCI_TENANCY

read aws_key_id aws_key_value <<< $(oci iam customer-secret-key create `
                                    --user-id $OCI_CS_USER_OCID `
                                    --display-name 'terraform-state-rw' `
                                    --query "data".{"AWS_ACCESS_KEY_ID:\"id\",AWS_SECRET_ACCESS_KEY:\"key\""} `
                                    | jq -r '.AWS_ACCESS_KEY_ID,.AWS_SECRET_ACCESS_KEY')

mkdir -p ~/.aws
tee ~/.aws/credentials <<EOF >/dev/null
[default]
aws_access_key_id=$aws_key_id
aws_secret_access_key=$aws_key_value
EOF