#!/bin/bash

if ! which aliyun;
  then
    echo "This certbot custom hook needs aliyun cli"
    exit 1
fi

if ! which jq;
  then
    echo "This certbot custom hook needs jq"
    exit 1
fi


function set_ali_domain(){
  ALI_DOMAIN=$(aliyun alidns DescribeDomains\
                --KeyWord $1\
                --SearchMode "EXACT" |\
                jq '.Domains.Domain[0].DomainName' --raw-output)
}

# Print Certbot params
echo "CERTBOT_DOMAIN: $CERTBOT_DOMAIN";
echo "CERTBOT_VALIDATION: $CERTBOT_VALIDATION"

#Check domain existence in alicloud
ROOT_DOMAIN="$CERTBOT_DOMAIN"
set_ali_domain "$ROOT_DOMAIN"

while [ "$ROOT_DOMAIN" != "$ALI_DOMAIN" ];
  do
    OLD_ROOT_DOMAIN="$ROOT_DOMAIN"
    ROOT_DOMAIN=${ROOT_DOMAIN#*.}
    if [ "$OLD_ROOT_DOMAIN" == "$ROOT_DOMAIN" ];
      then
        echo "No domain found in ali cloud"
        exit 1
      else
        set_ali_domain "$ROOT_DOMAIN"
    fi
  done

#Now ALI_DOMAIN has the right domain to use

# Retrieve eventual existing certbot acme_challenge records
RECORD="_acme-challenge"

RECORD_COUNT=$(aliyun alidns DescribeDomainRecords --DomainName $ALI_DOMAIN\
       --RRKeyWord $RECORD\
       --TypeKeyWord TXT\
       --SearchMode EXACT\
       | jq .TotalCount --raw-output)

if [ "$RECORD_COUNT" != "0" ];
  then
    echo "Existing _acme-challenge record, exiting";
    exit 1
fi

# REgistering challenge
aliyun alidns AddDomainRecord\
    --DomainName $ALI_DOMAIN\
    --RR $RECORD\
    --Type TXT\
    --Value $CERTBOT_VALIDATION\
    --TTL 600
