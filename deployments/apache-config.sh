#!/bin/bash

# Keycloak admin credentials
KEYCLOAK_URL="http://localhost:8080"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="password"

# Realm, client, and user details
REALM_NAME="apache-realm"
CLIENT_ID="apache-client"
USER_USERNAME="apache"
USER_PASSWORD="password"
OIDC_REDIRECT_URI="http://localhost:8080/auth"
VALID_URI="*"
CLIENT_SECRET="randome234string"

# Log in
export PATH=$PATH:/opt/keycloak/bin/
kcadm.sh config credentials --server $KEYCLOAK_URL --realm master --user $ADMIN_USERNAME --password $ADMIN_PASSWORD

# Create realm
kcadm.sh create realms -s realm=$REALM_NAME -s enabled=true

# Create client
kcadm.sh create clients -r $REALM_NAME -s clientId=$CLIENT_ID -s protocol=openid-connect -s directAccessGrantsEnabled=true -s publicClient=false -s secret=$CLIENT_SECRET -s "redirectUris=[\"$VALID_URI\"]"

# Create user
kcadm.sh create users -r $REALM_NAME -s username=$USER_USERNAME -s enabled=true
kcadm.sh set-password -r $REALM_NAME --username $USER_USERNAME --new-password $USER_PASSWORD


# Output Apache HTTPD OIDC configuration
echo ""
echo "-----------------------------------------------"
echo "-----------------------------------------------"
echo "Apache OIDC settings"
echo ""
echo "OIDCProviderMetadataURL $KEYCLOAK_URL/realms/$REALM_NAME/.well-known/openid-configuration"
echo "OIDCClientID $CLIENT_ID"
echo "OIDCClientSecret $CLIENT_SECRET"
echo "OIDCRedirectURI $OIDC_REDIRECT_URI"
echo "OIDCCryptoPassphrase sUper-sEcret-PASS-key"  

echo "-----------------------------------------------"
echo "-----------------------------------------------"

