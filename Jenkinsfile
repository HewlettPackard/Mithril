// Ubuntu image with the necessary dependencies for building Istio and AWS CLI
UBUNTU_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:istio-aws-deps"

// Start of the pipeline
pipeline {

  // Version of the Jenkins slave
  agent {
    label 'docker-v20.10'
  }

  // Nightly builds schedule only for master
  triggers { cron( BRANCH_NAME == "master" ?  "00 00 * * *" : "") }

  stages {

    stage('Notify Slack') {
      steps {
        script { 
          slackSend (channel: 'nathalia-satie.gomazako', message: 'hello')
        }
      }
    }
    stage('build-istio') {
      steps {
        // Istio clone from the release-1.10 branch
        sh '''
          git clone --single-branch --branch release-1.10 https://github.com/istio/istio.git
          ls
        '''
        // Fetch secrets from Vault and use the mask token plugin
        script {
          secrets = vaultGetSecrets()
          def passwordMask = [
            $class: 'MaskPasswordsBuildWrapper',
            varPasswordPairs: [
              [ password: secrets.dockerHubToken],
              [ password: secrets.dockerHubUsername],
              [ password: secrets.awsAccessKeyID],
              [ password: secrets.awsSecretAccessKeyID],
              [ password: secrets.awsAccountID]
            ]
          ]
          // Create the build tag
          def BUILD_TAG = makeTag()
          // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
          // and build tag, building Istio and pushing images to the Dockerhub of HPE
          wrap(passwordMask) {
            _ = docker.image(UBUNTU_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock -e DOCKER_HUB_HPE_TOKEN=\"${secrets.dockerHubToken}\" -e DOCKER_HUB_HPE_USER=\"${secrets.dockerHubUsername}\" -e TAG=\"${BUILD_TAG}\" ") {
              sh """
                export TAG=\"${BUILD_TAG}\"
                export BUILD_WITH_CONTAINER=0
                export GOOS=linux

                // cd istio
                // git apply ${WORKSPACE}/POC/patches/poc.1.10.patch

                // echo \"${secrets.dockerHubToken}\" | docker login hub.docker.hpecorp.net --username \"${secrets.dockerHubToken}\" --password-stdin
                
                // export HUB=hub.docker.hpecorp.net/sec-eng

                // make push
                
                // aws configure set aws_access_key_id \"${secrets.awsAccessKeyID}\"
                // aws configure set aws_secret_access_key \"${secrets.awsSecretAccessKeyID}\"
                // aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin \"${secrets.awsAccountID}\".dkr.ecr.us-east-1.amazonaws.com

                // export HUB=\"${secrets.awsAccountID}\".dkr.ecr.us-east-1.amazonaws.com/mithril

                // make push
              """
            }
          }
        }
      }
    }
  }

  post {
    failure {
      steps {
        script { 
          slackSend (channel: 'nathalia-satie.gomazako', message: 'hello')
        }
      }
    }
  }
}

// Method for creating the build tag
def makeTag() {
  return env.GIT_BRANCH + "_" + env.GIT_COMMIT.substring(0,7)
}
