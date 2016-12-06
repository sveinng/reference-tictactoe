#!groovy


node {

    currentBuild.result = "SUCCESS"

    try {

       stage 'Checkout'

            checkout scm

       stage 'Test'

            env.NODE_ENV = "test"
            print "Environment will be : ${env.NODE_ENV}"

            sh 'node -v'
            sh 'scripts/install-node-modules.sh'
            sh 'npm test'

       stage 'Build Docker'

            sh './scripts/build.sh'
            sh './scripts/build-docker.sh'

       stage 'Deploy'

            echo 'Delploy to AWS'
            sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) ami-9398d3e0'

       stage 'Cleanup'

            echo 'prune and cleanup'
            sh 'npm prune'
            sh 'rm node_modules -rf'

            slackSend channel: '#general', color: 'good', message: 'Yeah - TicTacToe built OK - Latest version on AWS http://tictactoe.sveinng.com/', teamDomain: 'hgop-svenni', token: 'umbD47dpxzKNkL8XpaEe74Xx'
            setBuildStatus("Build complete", "SUCCESS")
        }


    catch (err) {

        currentBuild.result = "FAILURE"
            slackSend channel: '#general', color: 'bad', message: "TicTacToe build error - log is here: ${env.BUILD_URL}", teamDomain: 'hgop-svenni', token: 'umbD47dpxzKNkL8XpaEe74Xx'

        throw err
    }

}


def setBuildStatus(message,state){
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/glossary95/java-maven-junit-helloworld"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ])
}

