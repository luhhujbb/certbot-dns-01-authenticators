# Certbot manual hook scripts for Alicloud DNS services

These two scripts are intended to be used to authenticate using ACME/letsencrypt
DNS-01 validation when your DNS zone is hosted by Alicloud service (Chinese major cloud
  provider).

## Configuration

Your aliyun cli must be present and configured (either with ram credentials or ecs instance ram role), jq must be installed

## Usage

```
$ certbot certonly \
  -- manual \
  --manual-auth-hook /opt/le-scripts/alicloud/auth.sh \
  --manual-cleanup-hook /opt/le-scripts/alicloud/cleanup.sh \
  -d '*.domain.tld'
```
