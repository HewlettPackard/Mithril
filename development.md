## Development

We curently support the following Istio branches:
 - master
 - 1.10
 - 1.11
 - 1.12

### Pull request instructions
Here is a suggestion to keep our pull requests proccess effective.
 1. **Pull Request check list**
    -   [ ] Documentation updated
    -   [ ] Proper tests/regressions included
    -   [ ] Pipeline build is succesful
 2. **Affected functionality**  
 3.  **Description of change**
 4.  **Which issue/task this PR fixes**

In order to merge a PR, **it is necessary to have at least one approval**. Since we are unable to block a PR with a failed pipeline, make sure that PRs are not merged if the pipeline for this PR is broken.

### Mithril images
Our private images are available at [ECR](https://console.aws.amazon.com/ecr/home?region=us-east-1) and [HPE HUB](https://hub.docker.hpecorp.net/), respectively, 
**529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril** and **hub.docker.hpecorp.net**.

For development purpouses, we have the following images:

 - Jenkins pipeline: (hub.docker.hpecorp.net/sec-eng/ubuntu:pipeline)
 - Mithril dependencies: (529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril)
	

## Distribution
At the moment, we provide images, scripts, and code patches.

The Mithril are uploaded to a private ECR and HPE HUB, under the **build-and-push-istio-images** stage at our pipeline. 

Our scripts and patches are uploaded to a public S3 bucket with versioning. This means that we download our current files by default, but the later versions are still available for consulting. This proccess occurs automaticaly within the **distribute-poc** stage at our pipeline, with the scripts and patches being uploaded in parallel. 

### Mithril images
Our images are available for customer at the a public ECR. Our public hub is **public.ecr.aws/e4m8j0n8/mithril**.

### Scripts assets

At **distribute-assets** stage, a tar.gz file is created with the desired assets.

    tar -zcvf mithril.tar.gz \
    bookinfo spire istio \
    deploy-all.sh create-namespaces.sh cleanup-all.sh \ 
    forward-port.sh create-kind-cluster.sh \ 
    doc/poc-instructions.md demo/demo-script.sh \ 
    demo/README.md demo/federation-demo.sh  \
    ../usecases/federation

Then, this tar file is uploaded to the bucket **s3://mithril-customer-assets** and set as publicly readable through an ACL object.

### Image patches

Then, this tar is uploaded to the bucket **s3://mithril-poc-patchset** and the tar is set as publicly readable through an ACL object.

    tar -zcvf mithril-poc-patchset.tar.gz patches

## Release 

### Mithril public images tags

Our current images are:
- stable_20211022
- stable_20210920 

