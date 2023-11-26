#!/bin/bash

sh -c 'java -jar /opt/gitbucket.war'
#java -jar /opt/gitbucket.war \
#  -Dgitbucket.home=${GITBUCKET_HOME} \
#  --connectors=${GITBUCKET_CONNECTORS} \
#  --port=${GITBUCKET_PORT} \
#  > /var/lib/gitbucket/gitbucket.log 2>&1

#  --key_store_path=${GITBUCKET_KEYSTOREPATH} \
#  --key_store_password=${GITBUCKET_KEYSTOREPASSWORD} \
#  --secure_port=${GITBUCKET_SECUREPORT} \
#  --redirect_https=${GITBUCKET_REDIRECTHTTPS} \

