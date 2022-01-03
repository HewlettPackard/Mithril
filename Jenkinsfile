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
        H H(0-3) * * * %ISTIO_BRANCH=master
        H H(0-3) * * * %ISTIO_BRANCH=release-1.10
        H H(0-3) * * * %ISTIO_BRANCH=release-1.11
        H H(0-3) * * * %ISTIO_BRANCH=release-1.12
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

    stage("build-and-push-dev-images-ecr"){
       environment {
         AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
         AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
       }
      steps {
        script {
          // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
          // and build tag, building Istio and pushing images to the ECR.
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {

            def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
            sh """#!/bin/bash

              aws ecr get-login-password --region ${ECR_REGION} | \
                docker login --username AWS --password-stdin ${ECR_REGISTRY}

              docker build -t mithril:${BUILD_TAG} \
                -f ./docker/Dockerfile .
              docker tag mithril:${BUILD_TAG} ${DEVELOPMENT_IMAGE}:${BUILD_TAG}
              docker push ${DEVELOPMENT_IMAGE}:${BUILD_TAG}
            """
          }
        }
      }
    }

    stage("unit-test") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
        ISTIO_BRANCH = "${params.ISTIO_BRANCH}"
      }
      steps {
        script {
          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh '''#!/bin/bash
              cd ${WORKSPACE}/terraform/istio-unit-tests

              echo "** Begin istio unit tests **"
              terraform init
              terraform apply -auto-approve -var "BUILD_TAG"=${BUILD_TAG} -var "AWS_PROFILE"=${AWS_PROFILE} -var "ISTIO_BRANCH"=${ISTIO_BRANCH}
              num_tries=0

              while [ $num_tries -lt 500 ];
              do
                aws s3api head-object --bucket mithril-artifacts --key "${BUILD_TAG}/${BUILD_TAG}-istio-unit-tests-log.txt" --no-cli-pager 2> /dev/null
                if [ $? -eq 0 ];
                  then
                    break;
                  else
                    ((num_tries++))
                    sleep 1;
                fi
              done

              terraform destroy -auto-approve

              aws s3 cp "s3://mithril-artifacts/${BUILD_TAG}/${BUILD_TAG}-istio-unit-tests-result.txt" .
              RESULT=$(tail -n 1 "${BUILD_TAG}-istio-unit-tests-result.txt" | grep -oE '^..')
              if [[ "$RESULT" == "ok" ]];
                then
                  echo "Istio unit tests successful"
                else
                  echo "Istio unit tests failed"
                  cat "${BUILD_TAG}-istio-unit-tests-result.txt"
                  exit 1
              fi
            '''
          }
        }
      }
    }

    stage("build-and-push-istio-images") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
        BUILD_WITH_CONTAINER = 0
      }

      steps {
        script {
          def passwordMask = [
            $class: 'MaskPasswordsBuildWrapper',
            varPasswordPairs: [ [ password: HPE_DOCKER_HUB_SECRET ] ]
          ]
          
          wrap(passwordMask) {
            docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {

              // Build and push to ECR registry
              def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com";
              def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX;

              sh """#!/bin/bash
                export HUB=${HPE_REGISTRY}
                export TAG=${BUILD_TAG}

                echo ${HPE_DOCKER_HUB_SECRET} | docker login hub.docker.hpecorp.net --username ${HPE_DOCKER_HUB_SECRET} --password-stdin

                # Checks go version dependencies
                . ./terraform/istio-unit-tests/check-go-version.sh

                cd istio && go get github.com/spiffe/go-spiffe/v2 && go mod tidy && make push

                aws ecr get-login-password --region ${ECR_REGION} | \
                  docker login --username AWS --password-stdin ${ECR_REGISTRY}

                docker images --format "{{.ID}} {{.Repository}}" | while read line; do
                  pieces=(\$line)
                  if [[ "\${pieces[1]}" == *"hub.docker.hpecorp.net"* ]] && [[ "\${pieces[1]}" != *"/ubuntu"* ]]; then
                    tag=\$(echo "\${pieces[1]}" | sed -e "s|^${HPE_REGISTRY}||")
                    docker tag "\${pieces[0]}" "${ECR_HUB}\${tag}:${BUILD_TAG}"
                    docker push "${ECR_HUB}\${tag}:${BUILD_TAG}"
                  fi
                done
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
          def ECR_REGISTRY = AWS_ACCOUNT_ID + ".dkr.ecr." + ECR_REGION + ".amazonaws.com"
          def ECR_HUB = ECR_REGISTRY + "/" + ECR_REPOSITORY_PREFIX

          docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock") {
            sh """#!/bin/bash
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

    stage("run-integration-tests") {
      environment {
        AWS_ACCESS_KEY_ID = "${AWS_ACCESS_KEY_ID}"
        AWS_SECRET_ACCESS_KEY = "${AWS_SECRET_ACCESS_KEY}"
      }

      steps {
        script {
          def folders = sh(script: 'cd terraform/integration-tests && ls -1', returnStdout: true).split()
          def builders = [:]

          folders.each{ folder ->
            builders[folder] = {
              stage("$folder") {
                script {
                  def usecase = folder
                  docker.image(BUILD_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock --name $usecase -e usecase=$usecase ") {
                    sh '''#!/bin/bash
                      cd terraform/integration-tests/${usecase}

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

              cd terraform/integration-tests

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
                  tar -zcvf mithril.tar.gz bookinfo spire istio configmaps.yaml \
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
