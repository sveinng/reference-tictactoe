#!groovy


node {

    try {

       stage 'Checkout'
            notifyBuild('STARTED')
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
// Disable aws provisioning for now
//            sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) ami-9398d3e0'

       stage 'Cleanup'

            echo 'prune and cleanup'
            sh 'npm prune'
            sh 'rm node_modules -rf'
            setBuildStatus("Build complete", "SUCCESS")

    } catch (err) {

        currentBuild.result = "FAILURE"
        throw err

    } finally {

        notifyBuild(currentBuild.result)

    }
}


def setBuildStatus(String message, String state){
  // build status of null means successful

  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/sveinng/reference-tictactoe"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ])
}

def notifyBuild(String buildStatus = 'STARTED') {
  // build status of null means successful
  buildStatus =  buildStatus ?: 'SUCCESSFUL'

  // Default values
  def defChan = '#general'
  def defTeam = 'hgop-svenni'
  def defToken = 'umbD47dpxzKNkL8XpaEe74Xx'
  def colorName = 'bad'
  def msg = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' - ${env.BUILD_URL}"

  // Override default values based on build status
  if (buildStatus == 'STARTED') {
    colorName = 'warning'
  } else if (buildStatus == 'SUCCESSFUL') {
    colorName = 'good'
  } else {
    colorName = 'bad'
  }

  // Send Slack
  slackSend (channel: defChan, color: colorName, message: msg, teamDomain: defTeam, token: defToken)
}
