#!/bin/sh

aws --endpoint-url http://localhost:8333 s3 rb s3://mybucket --force
aws --endpoint-url http://localhost:8333 s3 mb s3://mybucket
date > hello.txt
aws --endpoint-url http://localhost:8333 s3 cp hello.txt s3://mybucket/hello.txt
aws --endpoint-url http://localhost:8333 s3 ls s3://mybucket
aws --endpoint-url http://localhost:8333 s3 cp s3://mybucket/hello.txt ./hello_downloaded.txt
cat hello_downloaded.txt

