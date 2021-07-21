#!/bin/bash

aws s3api put-bucket-policy --bucket s3://mithril-customer-assets --policy file://s3-policy.json