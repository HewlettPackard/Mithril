#!/bin/bash

aws s3api put-bucket-policy --bucket mithril-customer-assets --policy file://s3-policy.json