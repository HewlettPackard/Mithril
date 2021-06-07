UBUNTU_IMAGE = "hub.docker.hpecorp.net/sec-eng/ubuntu:istio-deps"

pipeline {

    agent {
     label 'docker-v20.10'
    }

    triggers { cron('00 00 * * *') }

    stages {
        stage('build-istio') {
            steps {
                sh '''
                    git clone https://github.com/istio/istio.git
                    ls
                '''
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
                  def BUILD_TAG = makeTag()
                    wrap(passwordMask) {
                  _ = docker.image(UBUNTU_IMAGE).inside("-v /var/run/docker.sock:/var/run/docker.sock -e DOCKER_HUB_HPE_TOKEN=\"${secrets.dockerHubToken}\" -e DOCKER_HUB_HPE_USER=\"${secrets.dockerHubUsername}\" -e TAG=\"${BUILD_TAG}\" ") {
                    sh """
                      echo \"${secrets.dockerHubToken}\" | docker login hub.docker.hpecorp.net --username \"${secrets.dockerHubToken}\" --password-stdin

                      export PATH=$PATH:/usr/local/go/bin:/root/go/bin
                      export TAG=\"${BUILD_TAG}\"
                      export HUB=hub.docker.hpecorp.net/sec-eng
                      export BUILD_WITH_CONTAINER=0
                      export GOOS=linux
                      cd istio

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

def makeTag() {
    return env.GIT_BRANCH + "_" + env.GIT_COMMIT.substring(0,7)
}
