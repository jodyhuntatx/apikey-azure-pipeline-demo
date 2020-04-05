#!/bin/bash -x
#
# Authenticates as host identity with API key and gets value of a specified variable
#

# URL, ACCOUNT, CERT_FILE, LOGIN and API_KEY are taken from build vars in library

################  MAIN   ################
# Takes 1 argument:
#   $1 - name of variable to value to return
#
main() {
echo $CONJUR_AUTHN_API_KEY
  if [[ $# -ne 1 ]] ; then
    printf "\nUsage: %s <variable-name>\n" $0
    exit -1
  fi
  local variable_name=$1
				# authenticate, get ACCESS_TOKEN
  ACCESS_TOKEN=$(authn_host $CONJUR_AUTHN_LOGIN $CONJUR_AUTHN_API_KEY)
  if [[ "$ACCESS_TOKEN" == "" ]]; then
    echo "Authentication failed..."
    exit -1
  fi

  local encoded_var_name=$(urlify "$variable_name")
  curl -s \
	--cacert $CONJUR_CERT_FILE \
	-H "Content-Type: application/json" \
	-H "Authorization: Token token=\"$ACCESS_TOKEN\"" \
     $CONJUR_APPLIANCE_URL/secrets/$CONJUR_ACCOUNT/variable/$encoded_var_name
}

##################
# AUTHN HOST
#  $1 - host identity
#  $2 - API key
#
authn_host() {
  local host_id=$1; shift
  local api_key=$1; shift

  local encoded_host_id=$(urlify "$host_id")
  local response=$(curl -s \
		     --cacert $CONJUR_CERT_FILE \
                     --data $api_key \
                     $CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/$encoded_host_id/authenticate)
  access_token=$(echo -n $response| base64 | tr -d '\r\n')
  echo "$access_token"
}

################
# URLIFY - url encodes input string
# in: $1 - string to encode
# out: URLIFIED - global variable containing encoded string
urlify() {
        local str=$1; shift
        str=$(echo $str | sed 's= =%20=g')
        str=$(echo $str | sed 's=/=%2F=g')
        str=$(echo $str | sed 's=:=%3A=g')
        str=$(echo $str | sed 's=+=%2B=g')
        str=$(echo $str | sed 's=&=%26=g')
        str=$(echo $str | sed 's=@=%40=g')
        echo $str
}

main "$@"
