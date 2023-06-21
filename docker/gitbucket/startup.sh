#!/bin/bash

#sh -c 'java -jar /opt/gitbucket.war'
java -jar /opt/gitbucket.war \
  -Dgitbucket.home=${GITBUCKET_HOME} \
  --connectors=${GITBUCKET_CONNECTORS} \
  --redirect_https=${GITBUCKET_REDIRECTHTTPS} \
  --port=${GITBUCKET_PORT} \
  --secure_port=${GITBUCKET_SECUREPORT} \
  --key_store_path=${GITBUCKET_KEYSTOREPATH} \
  --key_store_password=${GITBUCKET_KEYSTOREPASSWORD} \
  > /var/lib/gitbucket/gitbucket.log 2>&1



