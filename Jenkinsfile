AWS_PROFILE = "mithril-jenkins"
BUILD_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:pipeline"
DEVELOPMENT_IMAGE = "529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril"
CHANNEL_NAME = "@U021L6LHSHM"
ECR_REGION = "us-east-1"
ECR_REPOSITORY_PREFIX = "mithril"
HPE_REGISTRY = "hub.docker.hpecorp.net/sec-eng"
LATEST_BRANCH = "1.10"
S3_PATCHSET_BUCKET = "s3://mithril-poc-patchset"
S3_CUSTOMER_BUCKET = "s3://mithril-customer-assets"
MAIN_BRANCH = "master"
PROXY="http://proxy.houston.hpecorp.net:8080"

def SLACK_ERROR_MESSAGE
def SLACK_ERROR_COLOR

// Start of the pipeline
pipeline {

  // Version of the Jenkins slave
  agent {
    label 'docker-v20.10'
  }

  environment {
    BUILD_TAG = makeTag()
    GOOS = "linux"
    AWS_ACCESS_KEY_ID = "${vaultGetSecrets().awsAccessKeyID}"
    AWS_SECRET_ACCESS_KEY = "${vaultGetSecrets().awsSecretAccessKeyID}"
    EC2_SSH_KEY = "${vaultGetSecrets().EC2SSHKey}"
  }
  
  // Nightly builds schedule only for master
  triggers { cron( BRANCH_NAME == MAIN_BRANCH ?  "00 00 * * *" : "") }

  stages {
    stage("notify-slack") {
      steps {
        script {
          slackSend (
            channel: CHANNEL_NAME,
            message: "Hello. The pipeline ${currentBuild.fullDisplayName} started. (<${env.BUILD_URL}|See Job>)")
        }
      }
    }

    stage("build-and-push-dev-images"){
      steps {
        script {
          def secrets = vaultGetSecrets()
          
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            def ECR_REGISTRY = secrets.awsAccountID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
            def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX;

            sh """
              aws ecr get-login-password --region ${ECR_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REGISTRY}
              
              docker build -t mithril:${BUILD_TAG} \
                --build-arg http_proxy=${PROXY} \
                --build-arg https_proxy=${PROXY} \
                -f ./docker/Dockerfile .
              docker tag mithril:${BUILD_TAG} ${DEVELOPMENT_IMAGE}:${BUILD_TAG}
              docker push ${DEVELOPMENT_IMAGE}:${BUILD_TAG}
            """
          }
        }
      }
    }

    stage("make-poc-codebase") {
      //remove
      when {
        branch MAIN_BRANCH
      }

      steps {
        // Istio clone from the latest branch
        sh "git clone --single-branch --branch release-${LATEST_BRANCH} https://github.com/istio/istio.git"

        // Apply Mithril patches
        sh """
          cd istio
          git apply \
            ${WORKSPACE}/POC/patches/poc.${LATEST_BRANCH}.patch \
            ${WORKSPACE}/POC/patches/fetch-istiod-certs.${LATEST_BRANCH}.patch \
            ${WORKSPACE}/POC/patches/unit-tests.${LATEST_BRANCH}.patch
        """
      }
    }

    stage("unit-test") {
      //remove
      when {
        branch MAIN_BRANCH
      }

      steps {
        sh """
          set -x
          export no_proxy="\${no_proxy},notpilot,:0,::,[::]"

          cd istio
          make clean
          make init
          make test
        """
      }
    }

    stage("build-and-push-poc-images") {
      //remove
      when {
        branch MAIN_BRANCH
      }

      environment {
        BUILD_WITH_CONTAINER = 0
      }
      steps {
        // Fetch secrets from Vault and use the mask token plugin
        script {
          def secrets = vaultGetSecrets()

          def passwordMask = [
            $class: 'MaskPasswordsBuildWrapper',
            varPasswordPairs: [ [ password: secrets.dockerHubToken ] ]
          ]

          // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
          // and build tag, building Istio and pushing images to the Dockerhub of HPE
          wrap(passwordMask) {
            docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
              // Build and push to HPE registry
              sh """
                export HUB=${HPE_REGISTRY}
                echo ${secrets.dockerHubToken} | docker login hub.docker.hpecorp.net --username ${secrets.dockerHubToken} --password-stdin
                cd istio && make push
              """

              // Build and push to ECR registry
              def ECR_REGISTRY = secrets.awsAccountID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
              def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX;

              sh """
                export HUB=${ECR_HUB}
                aws ecr get-login-password --region ${ECR_REGION} | \
                  docker login --username AWS --password-stdin ${ECR_REGISTRY}
                cd istio && make push
              """
            }
          }
        }
      }
    }

    // Tag the current build as "latest" whenever a new commit
    // comes into master and pushes the tag to the ECR repository
    stage("tag-latest-images") {
      when {
        branch MAIN_BRANCH
      }
      steps {
        script {
          def secrets = vaultGetSecrets()

          def ECR_REGISTRY = secrets.awsAccountID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com"
          def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX

          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh """#!/bin/bash
              set -x
              aws ecr get-login-password --region ${ECR_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REGISTRY}

              docker images "${ECR_HUB}/*" --format "{{.ID}} {{.Repository}}" | while read line; do
                pieces=(\$line)
                docker tag "\${pieces[0]}" "\${pieces[1]}":${env.BUILD_TAG}
                docker push "\${pieces[1]}":${env.BUILD_TAG}
              done
            """
          }
        }
      }
    }

    stage("run-integration-tests") {
      // when {
      //   branch MAIN_BRANCH
      // }

      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh '''#!/bin/bash
              cd terraform
              for FOLDER in *; do cd ${FOLDER} && terraform init && terraform apply -auto-approve -var "BUILD_TAG"=${BUILD_TAG} -var "AWS_PROFILE"=${AWS_PROFILE} && cd .. ;

              BUCKET_EXISTS=false
              num_tries=0

              while [ $num_tries -lt 500 ];
              do
                aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}.txt" --no-cli-pager
                if [ $? -eq 0 ];
                  then
                    BUCKET_EXISTS=true
                    break

                  else
                      ((num_tries++))
                      sleep 1;
                fi
              done

              terraform destroy -auto-approve

              done

              if $BUCKET_EXISTS;
                then
                  echo "Artifact object exists"
                  aws s3 cp "s3://mithril-artifacts/${BUILD_TAG}.txt" .

                else
                  echo "Artifact object does not exist"
                  exit 1
              fi

              if grep -q "no healthy upstream" "${BUILD_TAG}.txt";
                then
                  cat "${BUILD_TAG}.txt"
                  echo "Test failed"
                  exit 1

                else
                  echo "Test successful"
              fi
          '''
          }
        }
      }
    }

    stage("distribute-poc") {
      //remove
      when {
        branch MAIN_BRANCH
      }

      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh """
              cd ./POC

              tar -zcvf mithril.tar.gz bookinfo spire istio \
                deploy-all.sh create-namespaces.sh cleanup-all.sh forward-port.sh create-kind-cluster.sh create-docker-registry-secret.sh \
                doc/poc-instructions.md demo/demo-script.sh demo/README.md
              aws s3 cp mithril.tar.gz ${S3_CUSTOMER_BUCKET}


              tar -zcvf mithril-poc-patchset.tar.gz patches/poc-patchset-release-1.10.patch
              aws s3 cp mithril-poc-patchset.tar.gz ${S3_PATCHSET_BUCKET}
            """
          }
        }
      }
    }
  }

  post {
    success {
      slackSend (
        channel: CHANNEL_NAME,  
        color: 'good', 
        message: "The pipeline ${currentBuild.fullDisplayName} completed successfully. (<${env.BUILD_URL}|See Job>)"
      )
    }

    failure {
      script {
        SLACK_ERROR_MESSAGE = "Ooops! The pipeline ${currentBuild.fullDisplayName} failed."
        SLACK_ERROR_COLOR = "bad"
        if (BRANCH_NAME == MAIN_BRANCH) {
          SLACK_ERROR_MESSAGE = "@here The pipeline ${currentBuild.fullDisplayName} failed on `${MAIN_BRANCH}`"
          SLACK_ERROR_COLOR = "danger"
        }
      }
      slackSend (
        channel: CHANNEL_NAME,
        color: SLACK_ERROR_COLOR,
        message: "${SLACK_ERROR_MESSAGE} (<${env.BUILD_URL}|See Job>)",
      )
    }
  }
}

// Method for creating the build tag
def makeTag() {
  return env.GIT_BRANCH + "_" + env.GIT_COMMIT.substring(0,7)
}