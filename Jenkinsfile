// Ubuntu image with kind, k8s, go and all necessary dependencies for building Istio.
UBUNTU_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:istio-deps"

// Start of the pipeline
pipeline {

    // Version of the Jenkins slave
    agent {
     label 'docker-v20.10'
    }

    // Nightly builds schedule
    triggers { cron('00 00 * * *') }

    stages {
        stage('build-istio') {
            steps {
                // Istio clone from the master branch
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
                        [
                            password: secrets.dockerHubToken
                        ],
                        [
                            password: secrets.dockerHubUsername
                        ]
                    ]
                  ]
                  // Create the build tag
                  def BUILD_TAG = makeTag()
                  // Creating volume for the docker.sock, passing some environment variables for Dockerhub authentication
                  // and build tag, building Istio and pushing images to the Dockerhub of HPE
                    wrap(passwordMask) {
                  _ = docker.image(UBUNTU_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock -e DOCKER_HUB_HPE_TOKEN=\"${secrets.dockerHubToken}\" -e DOCKER_HUB_HPE_USER=\"${secrets.dockerHubUsername}\" -e TAG=\"${BUILD_TAG}\" ") {
                    sh """
                      echo \"${secrets.dockerHubToken}\" | docker login hub.docker.hpecorp.net --username \"${secrets.dockerHubToken}\" --password-stdin

                      export PATH=$PATH:/usr/local/go/bin:/root/go/bin
                      export TAG=\"${BUILD_TAG}\"
                      export HUB=hub.docker.hpecorp.net/sec-eng
                      export BUILD_WITH_CONTAINER=0
                      export GOOS=linux
                      pwd
                      ls
                      cd istio
                      git apply /home/jenkins/workspace/pire_f21-build-POC-patches-v1.10/patches/poc.1.10.patch

                      make docker
                      make push

                      docker images
                      docker ps
                    """
                    }
                  }
                }
            }
        }
    }
}

// Method for creating the build tag
def makeTag() {
    return env.GIT_BRANCH + "_" + env.GIT_COMMIT.substring(0,7)
}
