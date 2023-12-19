#!/bin/bash

#sh -c 'java -jar /opt/gitbucket.war > /var/log/gitbucket.log'

/opt/java/openjdk/bin/java -jar /opt/gitbucket.war \
  -Dgitbucket.home=${GITBUCKET_HOME} \
  --connectors=${GITBUCKET_CONNECTORS} \
  --port=${GITBUCKET_PORT} \
  --key_store_path=${GITBUCKET_KEYSTOREPATH} \
  --key_store_password=${GITBUCKET_KEYSTOREPASSWORD} \
  --secure_port=${GITBUCKET_SECUREPORT} \
  --redirect_https=${GITBUCKET_REDIRECTHTTPS} \
  --key_store_password=${GITBUCKET_KEYSTOREPASSWORD} \
  --key_manager_password=${GITBUCKET_KEYMANAGERPASSWORD} \
  > /gitbucket/gitbucket.log 2>&1


