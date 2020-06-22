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

RECORD_ID=$(aliyun alidns DescribeDomainRecords --DomainName $ALI_DOMAIN\
       --RRKeyWord $RECORD\
       --TypeKeyWord TXT\
       --SearchMode EXACT\
       | jq .DomainRecords.Record[0].RecordId --raw-output)

if [ "$RECORD_ID" == "null" ];
  then
    echo "_acme-challenge recordnot found, exiting";
    exit 1
fi

# REgistering challenge
aliyun alidns DeleteDomainRecord\
    --RecordId $RECORD_ID
