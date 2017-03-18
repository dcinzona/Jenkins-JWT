### Must configure a connected app with a digital certificate
### Code to generate the certificate:
    openssl req \
        -subj "/C=US/ST=DC/L=Washington, DC/O=SoundExchange/CN=AcumenSolutions.com" \
        -newkey rsa:2048 -nodes -keyout private.key \
        -x509 -days 3650 -out public.crt

- connected app must have "offline access" in scopes
- connected app must also be associated with the user / profile

### Jenkins

- The Jenkins job must support parameters
    - sf.username
    - sf.serverurl : https://test.salesforce.com or https://login.salesforce.com
    - jwt.clientid : the client ID of your connected app

Link to blog post that supported this development: http://doingpoorly.blogspot.com/2014/11/jwt-bearer-token-flow-can-be-used-for.html
