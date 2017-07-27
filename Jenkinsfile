#!groovy
node('docker') {
    slackJobDescription = "job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    try {
        stage "Build"
        checkout scm

        service = readProperties file: 'service.properties'

        git_commit = sh(returnStdout: true, script: "git rev-parse HEAD").trim()
        echo git_commit

        descriptive_version = sh(returnStdout: true, script: 'git describe --long --tags --dirty --always').trim()
        echo descriptive_version

        dockerRepo = "test-${env.BUILD_TAG}"

        sh "docker build --pull --no-cache --rm --build-arg git_commit=${git_commit} --build-arg descriptive_version=${descriptive_version} -t ${dockerRepo} ."

        image_sha = sh(returnStdout: true, script: "docker inspect -f '{{ .Config.Image }}' ${dockerRepo}").trim()
        echo image_sha

        writeFile(file: "${dockerRepo}.docker-image-sha", text: "${image_sha}")
        fingerprint "${dockerRepo}.docker-image-sha"

        dockerPusher = "push-${env.BUILD_TAG}"
        dockerPushRepo = "${service.dockerUser}/${service.repo}:${env.BRANCH_NAME}"
        dockerPushRepoUi = "${service.dockerUser}/ui-nginx:${env.BRANCH_NAME}"

        try {
            milestone 100
            lock("docker-push-${dockerPushRepo}") {
              milestone 101
              stage "Retag"
              sh "docker tag ${dockerRepo} ${dockerPushRepo}"

              milestone 102
              lock("docker-push-${dockerPushRepoUi}") {
                milestone 103
                stage "Build UI nginx"
                sh "docker build --no-cache --rm --build-arg git_commit=${git_commit} --build-arg descriptive_version=${descriptive_version} -t ${dockerPushRepoUi} -f Dockerfile.ui ."

                ui_image_sha = sh(returnStdout: true, script: "docker inspect -f '{{ .Config.Image }}' ${dockerPushRepoUi}").trim()
                echo ui_image_sha

                writeFile(file: "${dockerPushRepoUi}.docker-image-sha", text: "${ui_image_sha}")
                fingerprint "${dockerPushRepoUi}.docker-image-sha"

                stage "Docker Push"
                withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'jenkins-docker-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME']]) {
                    sh """docker run -e DOCKER_USERNAME -e DOCKER_PASSWORD \\
                                     -v /var/run/docker.sock:/var/run/docker.sock \\
                                     --rm --name ${dockerPusher} \\
                                     docker:\$(docker version --format '{{ .Server.Version }}') \\
                                     sh -e -c \\
                          'docker login -u \"\$DOCKER_USERNAME\" -p \"\$DOCKER_PASSWORD\" && \\
                           docker push ${dockerPushRepo} && \\
                           docker push ${dockerPushRepoUi} && \\
                           docker logout'"""
                }
              }
            }
        } finally {
            sh returnStatus: true, script: "docker kill ${dockerPusher}"
            sh returnStatus: true, script: "docker rm ${dockerPusher}"

            sh returnStatus: true, script: "docker rmi ${dockerRepo}"

            step([$class: 'hudson.plugins.jira.JiraIssueUpdater',
                    issueSelector: [$class: 'hudson.plugins.jira.selector.DefaultIssueSelector'],
                    scm: scm,
                    labels: [ "${service.repo}-${descriptive_version}" ]])
        }
    } catch (InterruptedException e) {
        currentBuild.result = "ABORTED"
        slackSend color: 'warning', message: "ABORTED: ${slackJobDescription}"
        throw e
    } catch (e) {
        currentBuild.result = "FAILED"
        sh "echo ${e}"
        slackSend color: 'danger', message: "FAILED: ${slackJobDescription}"
        throw e
    }
}
