#!/bin/bash
dnf update -y
dnf install -y httpd aws-cli
systemctl enable httpd
systemctl start httpd
aws s3 cp s3://s3-bucket-us-1/index.html /var/www/html/index.html
