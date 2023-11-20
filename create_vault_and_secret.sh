#! /bin/bash

SECRET=${1:-superstrongpassword}
SECRETNAME=${2:-ansiblevault}
VAULTNAME=${3:-ansible}

echo "Creating Vault"
VAULT_ID=$(oci kms management vault create \
    --compartment-id ${OCI_TENANCY} \
    --display-name ${VAULTNAME} \
    --vault-type=default \
    --wait-for-state ACTIVE | jq -r '.data.id')
echo "  Vault ID: ${VAULT_ID}"
ENDPOINT_ID=$(oci kms management vault get \
    --vault-id ${VAULT_ID} | jq -r '.data."management-endpoint"')
echo "  Endpoint: ${ENDPOINT_ID}"

# while vault is active, endpoint can take extra time to become available
echo "Waiting for endpoint to become active"
sleep 60

echo "Creating Vault Master Key"
KEY_ID=$(oci kms management key create \
    --compartment-id ${OCI_TENANCY} \
    --display-name "${VAULTNAME}-key" \
    --key-shape '{"algorithm":"AES","length":"16"}' \
    --endpoint ${ENDPOINT_ID} \
    --wait-for-state ENABLED | jq -r '.data.id')
echo "  Encryption Key ID: ${KEY_ID}"

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
    --secret-content-stage CURRENT \
    --wait-for-state ACTIVE | jq -r '.data.id')
echo "Setting ANSIBLE_VAULT_SECRET_ID environment variable"
echo "export ANSIBLE_VAULT_SECRET_ID=${SECRET_ID}" | tee -a ~/.bashrc > /dev/null
source ~/.bashrc > /dev/null
echo "  Secret ID: ${SECRET_ID}"

echo "Creating Dynamic Group and Policy"
oci iam dynamic-group create  \
    --compartment-id ${OCI_TENANCY} \
    --name "${SECRETNAME}-access-group" \
    --description "Ansible Vault Access" \
    --matching-rule "any { instance.compartment.id = '${OCI_TENANCY}' }" 
    
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

echo "Anbile Vault master password is now stored in OCI Vault."
echo "  Use the script ansible/vault_key.py to retrive the password."