# AWS policies

You manage access in AWS by creating policies and attaching them to IAM identities (users, groups of users, or roles) or AWS resources. A policy is an object in AWS that, when associated with an identity or resource, defines their permissions. 

There are many types of AWS policies, one of them is **resource-based policies**. They are inline policies attached to resources.

Policies usually contain a "**Version**" and one or more **Statement**. 
As a best practice, always use the latest 2012-10-17 version, and the content of "Statement" depends on the policy type.

Resource-based policies contain four main elements in their Statement:
- **"Effect"**: Use Allow or Deny to indicate whether the policy allows or denies access.
- **"Action"**: Include a list of actions that the policy allows or denies, and they are related to the resource.
- **"Resource"**: Specify a list of resources to which the actions apply. If you do not include this element, then the resource to which the action applies is the resource to which the policy is attached.
- **"Principal"**: Indicate the account, user, role, or federated user to which you would like to allow or deny access.

There is also **"Sid"**, which is optional, and is responsible for providing a statement ID to differentiate between statements.

```
{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "FirstStatement",
        "Effect": "Allow",
        "Action": ["ResourceActionOne", "ResourceActionTwo"],
        "Resource": ["ResourceOne", "ResourceTwo"], 
        "Principal": ["IAMIdentityOne", "IAMIdentityTwo"]
    }]
}
```

Since groups are not considered IAM principals, it is not possible to share resources with them.

## Applying resource-based policies for S3

[Our bucket](https://s3.console.aws.amazon.com/s3/buckets/mithril-customer-assets?region=us-east-1&tab=objects) name is `mithril-customer-assets` and it is located at region `us-east-1`.

In order to give reading access to our files for a user outside scytale-dev AWS account, we need to allow the actions `S3:GetObject` and `s3:ListBucket`. `s3:GetObject` needs an object as a resource, and `s3:ListBucket` needs a bucket, so, respectively, the resources are going to be `s3://mithril-customer-assets/*` and `s3://mithril-customer-assets`.

A sample policy for sharing our S3 with an IAM User is available at `s3-policy.json` and it can be applied using the [apply-s3-policy.sh](apply-s3-policy.sh) script.

To check the current policies:
```
aws s3api get-bucket-policy --bucket mithril-customer-assets
```

## Applying resource-based policies for ECR

Amazon ECR repository policies are a subset of IAM policies that are scoped for, and specifically used for, controlling access to individual Amazon ECR repositories.

[Our images](https://console.aws.amazon.com/ecr/repositories?region=us-east-1) are at us-east-1, under multiple repositories, with prefix name `mithril`.

In order to give reading access to our images for a user outside scytale-dev AWS account, we need to allow the actions `ecr:BatchGetImage` and `ecr:GetDownloadUrlForLayer`. Since the resource-based policy is applied to a specific repository, it is not necessary to add a resource.

A sample policy for sharing our ECR with an IAM Account is available at `ecr-policy.json` and it can be applied using the [apply-ecr-policy.sh](apply-ecr-policy.sh) script.

To check the current policies:
```
aws ecr get-repository-policy --repository-name mithril/app
```

## Customers

Our assets are available for the following accounts:

- 532440004545 Nath
- 537868109139 GSE Team
