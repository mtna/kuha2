#!/bin/sh
#
# Kuha2 script to update document store from DDI-XML documents stored under the /metadata directrory
# The Output of kuha_upsert is logged under /var/log/kuha2
#
ME=$(basename $0)
LOGSTAMP=$(date +'%Y%m%d')

# Update Kuha2 metadata
NOW=$(date +'%Y-%m-%d %H:%M:%S,%3N')
echo >&1 "$NOW $ME: Updating Kuha2 metadata"
cd /usr/local/kuha2
. kuha_client-env/bin/activate
kuha_sync --document-store-url http://localhost:6001/v0 /metadata 2>>/var/log/kuha2/kuha2-sync_$LOGSTAMP.log 
NOW=$(date +'%Y-%m-%d %H:%M:%S,%3N')
echo >&1 "$NOW $ME: Kuha2 sync completed"
