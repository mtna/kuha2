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
python3 -m kuha_client.kuha_upsert --document-store-url http://localhost:6001/v0 --remove-absent --collection studies --collection variables --collection questions /metadata 2>>/var/log/kuha2/kuha2-update_$LOGSTAMP.log 
NOW=$(date +'%Y-%m-%d %H:%M:%S,%3N')
echo >&1 "$NOW $ME: Kuha2 update completed"
