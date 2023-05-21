#!/bin/bash

#sh -c 'java -jar /opt/gitbucket.war'
java -jar /opt/gitbucket.war \
  -Dgitbucket.home=${GITBUCKET_HOME} \
  --connectors=${GITBUCKET_CONNECTORS} \
  --redirect_https=${GITBUCKET_REDIRECTHTTPS} \
  --port=${GITBUCKET_PORT} \
  --secure_port=${GITBUCKET_SECUREPORT} \
  > /var/lib/gitbucket/gitbucket.log 2>&1



