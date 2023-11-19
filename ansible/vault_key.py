#! /usr/bin/python3

import oci
import base64
import sys
import os
import logging

# If running in Cloud Shell
if 'OCI_CS_USER_OCID' in os.environ:
    config = config = oci.config.from_file(
        "/etc/oci/config",
        "DEFAULT")
# If running outside of Cloud Shell
else:
    config = config = oci.config.from_file(
        "~/.oci/config"
        "DEFAULT")

def read_secret_value(secret_client, secret_id):    
    response = secret_client.get_secret_bundle(secret_id)
    
    base64_Secret_content = response.data.secret_bundle_content.content
    base64_secret_bytes = base64_Secret_content.encode('ascii')
    base64_message_bytes = base64.b64decode(base64_secret_bytes)
    secret_content = base64_message_bytes.decode('ascii')
    
    return secret_content


if 'ANSIBLE_VAULT_SECRET_ID' in os.environ:
    secret_id = os.environ['ANSIBLE_VAULT_SECRET_ID']
else:
    print('ANSIBLE_VAULT_SECRET_ID environment variable must be set')
    exit(1)

secret_client = oci.secrets.SecretsClient(config)
secret_contents = read_secret_value(secret_client, secret_id)
print(format(secret_contents))