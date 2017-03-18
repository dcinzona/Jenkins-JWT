#!/bin/bash

if [ $# -lt 3 ]; then
 echo 1>&2 "
 usage: $0 username loginurl clientid"
 echo "
 LOGIN URL values:
    sandbox: https://test.salesforce.com
    production: https://login.salesforce.com
"
 exit 2
fi

#Must configure a connected app with a digital certificate
#Code to generate the certificate:
#openssl req \
#    -subj "/C=US/ST=DC/L=Washington, DC/O=EAI/CN=AcumenSolutions.com" \
#    -newkey rsa:2048 -nodes -keyout private.key \
#    -x509 -days 3650 -out public.crt

#connected app must have "offline access" in scopes
#connected app must also be associated with the user / profile

export USERNAME=$1
export LOGINURL=$2
export CLIENTID=$3

#from https://help.salesforce.com/HTViewHelpDoc?id=remoteaccess_oauth_jwt_flow.htm#create_token

#step 1
jwtheader='{ "alg" : "RS256" }'

#step 2
jwtheader64=`echo -n "$jwtheader" | openssl enc -a -A | tr -d '=' | tr '/+' '_-'` # base64 | tr '+/' '-_' | sed -e 's/=*$//'`

timenow=`TZ=EST5EDT date +%s`
expires=`expr $timenow + 300`

#step3
claims=`printf '{ "iat":%s, "iss":"%s", "aud":"%s", "sub":"%s", "exp":%s }' $timenow $CLIENTID $LOGINURL $USERNAME $expires`

#step4
claims64=`echo -n "$claims" | openssl enc -a -A | tr -d '=' | tr '/+' '_-'` # base64 | tr '+/' '-_' | sed -e 's/=*$//'`

#step5
token=`printf '%s.%s' $jwtheader64 $claims64`

#step6
signature=`echo -n $token | openssl dgst -sha256 -binary -sign private.key | openssl enc -a -A | tr -d '=' | tr '/+' '_-'` #  base64 | tr '+/' '-_' | sed -e 's/=*$//'`

#step7
#bigstring=`echo "$token.$signature"`
bigstring=`printf '%s.%s' $token $signature`

response=`curl --silent \
 --data-urlencode grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer \
 --data-urlencode assertion=$bigstring $LOGINURL/services/oauth2/token`

export ACCESS_TOKEN=`echo $response | sed -n 's/^.*"access_token":"\([^"]*\)".*$/\1/p'`
export INSTANCE=`echo $response | sed -n 's/^.*"instance_url":"\([^"]*\)".*$/\1/p'`

if [ -n "$ACCESS_TOKEN" ]
then
    echo "jwt.token=$ACCESS_TOKEN
jwt.instance=$INSTANCE
jwt.response=${response}
jwt.t=${token}
jwt.bigstring=${bigstring}
jwt.signature=${signature}" # > token
else
    echo "jwt.t=${token}
jwt.token=$response
jwt.instance=$bigstring"
fi

 #set -x
 #cat token
