#! /bin/bash

SECRET=${1:-superstrongpassword}
SECRETNAME=${2:-ansiblevault}
VAULTNAME=${3:-ansible}

echo "Creating Vault"
VAULT_ID=$(oci kms management vault create \
    --compartment-id ${OCI_TENANCY} \
    --display-name ${VAULTNAME} \
    --vault-type=default | jq -r '.data.id')
ENDPOINT_ID=$(oci kms management vault get \
    --vault-id ${VAULT_ID} | jq -r '.data."management-endpoint"')
KEY_ID=$(oci kms management key create \
    --compartment-id ${OCI_TENANCY} \
    --display-name "${VAULTNAME}-key" \
    --key-shape '{"algorithm":"AES","length":"16"}' \
    --endpoint ${ENDPOINT_ID} | jq -r '.data.id')

echo "Creating Secret"
SECRET_BASE64=$(echo -n "${SECRET}" | base64)
SECRET_ID=$(oci vault secret create-base64 \
    --compartment-id ${OCI_TENANCY} \
    --secret-name ${SECRETNAME} \
    --vault-id ${VAULT_ID} \
    --description "Ansible Vault Master Password" \
    --key-id ${KEY_ID} \
    --secret-content-content ${SECRET_BASE64} \
    --secret-content-name ${SECRETNAME} \
    --secret-content-stage CURRENT | jq -r '.data.id')
echo ${SECRET_ID} | tee ~/.ansible_vault_secret_id
echo "export ANSIBLE_VAULT_SECRET_ID=${SECRET_ID}" | tee -a ~/.bash_profile
source ~/.bash_profile

echo "Creating Dynamic Group and Policy"
oci iam dynamic-group create  \
    --compartment-id ${OCI_TENANCY} \
    --name "${SECRETNAME}-access-group" \
    --description "Ansible Vault Access" \
    --matching-rule "any { instancd.compart.id = '${OCI_TENANCY}' }" 
    
tee vaultpolicy.json <<EOF
[
  "allow dynamic-group '${SECRETNAME}-access-group' to read secret-family in tenancy  where target.secret.name = '${SECRETNAME}'"
]
EOF
oci iam policy create \
    --compartment-id $OCI_TENANCY \
    --description "Ansible Vault Access" \
    --name "${SECRETNAME}-access-policy" \
    --statements file://vaultpolicy.json 

