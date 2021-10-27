AWS_PROFILE = "mithril-jenkins"
BUILD_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:pipeline"
DEVELOPMENT_IMAGE = "529024819027.dkr.ecr.us-east-1.amazonaws.com/mithril"
CHANNEL_NAME = "#notify-project-mithril"
ECR_REGION = "us-east-1"
ECR_REPOSITORY_PREFIX = "mithril"
HPE_REGISTRY = "hub.docker.hpecorp.net/sec-eng"
ISTIO_STABLE_BRANCH = "release-1.10" // the Istio branch to be distributed
PATCHSET_BUCKET = "mithril-poc-patchset"
CUSTOMER_BUCKET = "mithril-customer-assets"
MITHRIL_MAIN_BRANCH = "master"
PROXY = "http://proxy.houston.hpecorp.net:8080"

def SLACK_ERROR_MESSAGE
def SLACK_ERROR_COLOR

// Start of the pipeline
pipeline {

  options {
    timestamps()
    ansiColor('xterm')
  }

  // Version of the Jenkins slave
  agent {
    label 'docker-v20.10'
  }

  environment {
    BUILD_TAG = makeTag()
    GOOS = "linux"
  }
  
  parameters {
    string(name: 'ISTIO_BRANCH', defaultValue: ISTIO_STABLE_BRANCH, description: 'The Istio branch to run against')
  }

  triggers {
    parameterizedCron(
      BRANCH_NAME == MITHRIL_MAIN_BRANCH ? '''
        H H(0-3) * * * %ISTIO_BRANCH=release-1.10
        H H(0-3) * * * %ISTIO_BRANCH=release-1.11
      ''': ''
    )
  }

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

    stage("setup-pipeline") {
      steps {
        script {
          def secrets = vaultGetSecrets()

          AWS_ACCOUNT_ID = "${secrets.awsAccountID}"
          AWS_ACCESS_KEY_ID = "${secrets.awsAccessKeyID}"
          AWS_SECRET_ACCESS_KEY = "${secrets.awsSecretAccessKeyID}"
          HPE_DOCKER_HUB_SECRET = "${secrets.dockerHubToken}"
        }
      }
    }

    stage("make-poc-codebase") {
      steps {
        // Istio clone from the specified branch
        sh "git clone --single-branch --branch ${params.ISTIO_BRANCH} https://github.com/istio/istio.git"

        // Apply Mithril patches
        sh """
          cd istio
          git apply ${WORKSPACE}/POC/patches/poc.${params.ISTIO_BRANCH}.patch
        """
      }
    }

    stage("unit-test") {
      options {
        retry(3)
      }
      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh """
              set -x
              export no_proxy="\${no_proxy},notpilot,xyz,:0,::,[::],::0,[::0],::1,[::1]"

              cd istio
              make clean
              go mod tidy
              make init
              make test
            """
          }
        }
      }
    }

    stage("build-ecr-images") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }    

      failFast true
      parallel {
        stage("build-and-push-dev-images-ecr"){
          steps {
            script {
              // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
              // and build tag, building Istio and pushing images to the ECR
              docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {

                def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
                sh """#!/bin/bash

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

        stage("build-and-push-poc-images-ecr") {
          environment {
            BUILD_WITH_CONTAINER = 0
          }
          steps {
            script {
              docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
              
                // Build and push to ECR registry
                def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
                def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX;

                sh """#!/bin/bash
                  export HUB=${ECR_HUB}
                  export TAG=${BUILD_TAG}

                  aws ecr get-login-password --region ${ECR_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REGISTRY}
                  cd istio && go mod tidy && make push
                """
              }
            }
          }
        }
      }
    }

    stage("build-and-push-poc-images-hpe-hub") {
      environment {
        BUILD_WITH_CONTAINER = 0
      }
      steps {
        // Use the mask token plugin
        script {
          def passwordMask = [
            $class: 'MaskPasswordsBuildWrapper',
            varPasswordPairs: [ [ password: HPE_DOCKER_HUB_SECRET ] ]
          ]

          // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
          // and build tag, building Istio and pushing images to the Dockerhub of HPE
          wrap(passwordMask) {
            docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
              // Build and push to HPE registry
              sh """
                export HUB=${HPE_REGISTRY}
                export TAG=${BUILD_TAG}
                echo ${HPE_DOCKER_HUB_SECRET} | docker login hub.docker.hpecorp.net --username ${HPE_DOCKER_HUB_SECRET} --password-stdin
                cd istio && go mod tidy && make push
              """
            }
          }
        }
      }
    }

    // Tag the current build as "latest" whenever a new commit
    // comes into master and pushes the tag to the ECR repository
    stage("tag-latest-images") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }    

      when {
        allOf {
          branch MITHRIL_MAIN_BRANCH
          equals expected: ISTIO_STABLE_BRANCH, actual: params.ISTIO_BRANCH 
        }
      }
      
      steps {
        script {
          def passwordMask = [
            $class: 'MaskPasswordsBuildWrapper',
            varPasswordPairs: [ [ password: AWS_ACCESS_KEY_ID ],[password: AWS_SECRET_ACCESS_KEY ]]
          ]

          def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com"
          def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX

          wrap(passwordMask) {
            docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
              sh """#!/bin/bash
                set -x
                    
                aws ecr get-login-password --region ${ECR_REGION} | \
                  docker login --username AWS --password-stdin ${ECR_REGISTRY}

                docker images "${ECR_HUB}/*" --format "{{.ID}} {{.Repository}}" | while read line; do
                  pieces=(\$line)
                  docker tag "\${pieces[0]}" "\${pieces[1]}":latest
                  docker push "\${pieces[1]}":latest
                done
              """
            }
          }
        }
      }
    }

    stage("run-integration-tests") {  
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_PROFILE = "${AWS_PROFILE}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }    

      steps {
        script {
          def folders = sh(script: 'cd terraform && ls -1', returnStdout: true).split()
          def builders = [:]
          
          folders.each{ folder ->
            builders[folder] = {
              stage("$folder") {
                script {
                  def usecase = folder
                  docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock --name $usecase -e usecase=$usecase ") {
                    sh '''#!/bin/bash
                      cd terraform/${usecase} 

                      echo "** Begin test ${usecase} **" 
                      terraform init 
                      terraform apply -auto-approve -var "BUILD_TAG"=${BUILD_TAG} -var "AWS_PROFILE"=${AWS_PROFILE}
                      num_tries=0
                      while [ $num_tries -lt 500 ];
                      do
                        aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}/${BUILD_TAG}-${usecase}-log.txt" --no-cli-pager 2> /dev/null
                        if [ $? -eq 0 ];
                          then
                            break;
                          else
                            ((num_tries++))
                            sleep 1;
                        fi
                      done
                    
                      terraform destroy -auto-approve
                    '''
                  }
                }
              }
            }
          }
          parallel builders
        }
      }
    }

    stage("analyze-integration-tests") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }

      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh '''#!/bin/bash
              RESULT_LIST=()
              
              cd terraform

              HAS_MISSING_ARTIFACTS=false 
              for FOLDER in *;
                do
                  BUCKET_EXISTS=false
                  aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt" --no-cli-pager
                  if [ $? -eq 0 ];
                    then 
                      BUCKET_EXISTS=true
                  fi
                  if $BUCKET_EXISTS;
                    then
                      echo "Artifact object for usecase ${FOLDER} exists"
                    else
                      echo "Artifact ${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt object for usecase ${FOLDER} does not exist"
                      HAS_MISSING_ARTIFACTS=true
                  fi
                done

              if $HAS_MISSING_ARTIFACTS;
                then
                  echo "One or more artifacts do not exist"
                  exit 1
                else
                  echo "All artifacts found"
              fi

              HAS_FAILED_TEST=false
              for FOLDER in *;
                do
                  aws s3 cp "s3://mithril-artifacts/${BUILD_TAG}/${BUILD_TAG}-${FOLDER}-result.txt" .
                  RESULT=$(tail -n 1 "${BUILD_TAG}-${FOLDER}-result.txt" | grep -oE '^..')
                  if [ "$RESULT" == "ok" ];
                    then
                      echo "Test for usecase ${FOLDER} successful"
                    else
                      echo "Test for usecase ${FOLDER} failed"
                      cat "${BUILD_TAG}-${FOLDER}-result.txt"
                      HAS_FAILED_TEST=true
                  fi
                done

              if $HAS_FAILED_TEST;
                then
                  echo "One or more tests have failed"
                  exit 1
              fi
            '''
          }
        }
      }           
    }

    stage("distribute-poc") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }

      when {
        allOf {
          branch MITHRIL_MAIN_BRANCH
          equals expected: ISTIO_STABLE_BRANCH, actual: params.ISTIO_BRANCH 
        }
      }

      failFast true
      parallel {
        stage("distribute-assets") {
          steps {
            script {
              def S3_CUSTOMER_BUCKET = "s3://" + CUSTOMER_BUCKET 

              docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
                sh """
                  cd ./POC
                  tar -zcvf mithril.tar.gz bookinfo spire istio \
                    deploy-all.sh create-namespaces.sh cleanup-all.sh forward-port.sh create-kind-cluster.sh \
                    doc/poc-instructions.md demo/demo-script.sh demo/README.md demo/federation-demo.sh ../usecases/federation
                  aws s3 cp mithril.tar.gz ${S3_CUSTOMER_BUCKET}
                  aws s3api put-object-acl --bucket ${CUSTOMER_BUCKET} --key mithril.tar.gz --acl public-read
                """
              }
            }
          }
        }

        stage("distribute-patches") {
          steps {
            script {
              def S3_PATCHSET_BUCKET = "s3://" + PATCHSET_BUCKET

              docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
                sh """
                  cd ./POC
                  tar -zcvf mithril-poc-patchset.tar.gz patches
                  aws s3 cp mithril-poc-patchset.tar.gz ${S3_PATCHSET_BUCKET}
                  aws s3api put-object-acl --bucket ${PATCHSET_BUCKET} --key mithril-poc-patchset.tar.gz --acl public-read
                """
              }
            }
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
        if (BRANCH_NAME == MITHRIL_MAIN_BRANCH) {
          SLACK_ERROR_MESSAGE = "@channel The pipeline ${currentBuild.fullDisplayName} failed on `${BRANCH_NAME}`"
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
  def today = new Date()
  return today.format("dd-MM-yyyy") + "-" + params.ISTIO_BRANCH + "-" + env.GIT_BRANCH + "-" + env.GIT_COMMIT.substring(0,7)
}
