#!/bin/sh
ME=$(basename $0)
echo >&1 "$ME: Starting cron"
service cron start
echo >&1 "$ME: Starting MongoDB"
mongod --fork --logpath /var/log/mongodb/mongod.log
cd /usr/local
echo >&1 "$ME: Starting Kuha2 document store"
./kuha2/kuha_document_store/scripts/run_kuha_document_store.sh 2>/var/log/kuha2/document_store.log &
echo >&1 "$ME: Starting Kuha2 OSMH handler"
./kuha2/kuha_osmh_repo_handler/scripts/run_kuha_osmh_repo_handler.sh --document-store-url=localhost:6001 2>/var/log/kuha2/osmh.log &
echo >&1 "$ME: Starting Kuha2 OAI-PMH handler"
./kuha2/kuha_oai_pmh_repo_handler/scripts/run_kuha_oai_pmh_repo_handler.sh 2>/var/log/kuha2/oai-pmh.log &
