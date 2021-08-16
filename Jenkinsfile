BUILD_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:pipeline"
CHANNEL_NAME = "#notify-project-mithril"
ECR_REGION = "us-east-1"
ECR_REPOSITORY_PREFIX = "mithril"
HPE_REGISTRY = "hub.docker.hpecorp.net/sec-eng"
LATEST_BRANCH = "1.10"
S3_BUCKET = "s3://mithril-customer-assets"
AWS_PROFILE = "scytale"
MAIN_BRANCH = "master"

def SLACK_ERROR_MESSAGE
def SLACK_ERROR_COLOR

// Start of the pipeline
pipeline {

  // Version of the Jenkins slave
  agent {
    label 'docker-v20.10'
  }

  environment {
    TAG = makeTag() 
    BUILD_WITH_CONTAINER = 0
    GOOS = "linux"
    AWS_ACCESS_KEY_ID = "${vaultGetSecrets().awsAccessKeyID}"
    AWS_SECRET_ACCESS_KEY = "${vaultGetSecrets().awsSecretAccessKeyID}"
    EC2_SSH_KEY = "${vaultGetSecrets().EC2SSHKey}"
  }
  
  // Nightly builds schedule only for master
  triggers { cron( BRANCH_NAME == MAIN_BRANCH ?  "00 00 * * *" : "") }


  stages {
    // stage("notify-slack") {
    //   steps {
    //     script {
            // slackSend (
            //   channel: CHANNEL_NAME,
            //   message: "Hello. The pipeline ${currentBuild.fullDisplayName} started. (<${env.BUILD_URL}|See Job>)")
    //     }
    //   }
    // }

    stage("build-and-push-dev-images"){
      when {
        branch "master"
      }

      steps {
        script {
          def secrets = vaultGetSecrets()
          
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            def ECR_REGISTRY = secrets.awsAccountID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
            def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX;

            sh """
              aws ecr get-login-password --region ${ECR_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REGISTRY}
              
              cd docker 

              docker build -t mithril \
                --build-arg http_proxy=http://proxy.houston.hpecorp.net:8080 \
                --build-arg https_proxy=http://proxy.houston.hpecorp.net:8080 \
                -f ./Dockerfile .. 
              docker tag mithril:latest 529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril:latest
              docker push 529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril:latest
            """
          }
        }
      }
    }

    stage("make-poc-codebase") {
      // Remove
      when {
        branch "master"
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
      // Remove
      when {
        branch "master"
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
      // Remoooove
      when {
        branch "master"
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
                docker tag "\${pieces[0]}" "\${pieces[1]}":${env.TAG}
                docker push "\${pieces[1]}":${env.TAG}
              done
            """
          }
        }
      }
    }
    
    stage("run-integration-tests") {
      // when {
      //   branch "master"
      // }
      
      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh '''#!/bin/sh
              set -e

              cd terraform
              terraform init
              terraform plan
              terraform apply -auto-approve

              echo $EC2_SSH_KEY | base64 -d >> key.pem
              EC2_INSTANCE_IP=$(terraform output | grep -oP "server_public_ip = '\\K[^']+")
              # EC2_INSTANCE_IP="18.215.27.189"
              cat deploy-poc.sh | ssh -i key.pem -oStrictHostKeyChecking=no ubuntu@$EC2_INSTANCE_IP
              sleep 2
              cat test-poc.sh | ssh -i key.pem -oStrictHostKeyChecking=no ubuntu@$EC2_INSTANCE_IP | grep "Simple Bookstore App" | tr -d ' ' > test-response
              # compare files
              terraform destroy -auto-approve
            '''
          }
        }
      }
    }
  }
  
  // post {
  //   success {
  //     slackSend (
  //       channel: CHANNEL_NAME,  
  //       color: 'good', 
  //       message: "The pipeline ${currentBuild.fullDisplayName} completed successfully. (<${env.BUILD_URL}|See Job>)"
  //     )
  //   }
  //   failure {
  //     script {
  //       SLACK_ERROR_MESSAGE = "Ooops! The pipeline ${currentBuild.fullDisplayName} failed."
  //       SLACK_ERROR_COLOR = "bad"
  //       if (BRANCH_NAME == MAIN_BRANCH) {
  //         SLACK_ERROR_MESSAGE = "@here The pipeline ${currentBuild.fullDisplayName} failed on `${MAIN_BRANCH}`"
  //         SLACK_ERROR_COLOR = "danger"
  //       }
  //     }
  //     slackSend (
  //       channel: CHANNEL_NAME,
  //       color: SLACK_ERROR_COLOR,
  //       message: "${SLACK_ERROR_MESSAGE} (<${env.BUILD_URL}|See Job>)",
  //     )
  //   }
  // }
}

// Method for creating the build tag
def makeTag() {
  return env.GIT_BRANCH + "_" + env.GIT_COMMIT.substring(0,7)
}
