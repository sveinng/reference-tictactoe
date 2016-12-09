#!groovy


node {

    try {
       // Check out source from Github
       stage('Checkout') {
            notifyBuild('STARTED')
            checkout scm
       }

       // Prepare build environment and run unit tests
       stage('Test') {
            env.NODE_ENV = "test"
            print "Testing environment will be : ${env.NODE_ENV}"
            sh 'node -v'
            sh 'npm -v'
            sh 'scripts/install-node-modules.sh'
            sh 'npm test'
       }

       // Build Docker images from scratch and push to Docker hub
       stage('Build Docker') {
            sh './scripts/build.sh'
            sh './scripts/delete-all-dockers.sh'
            sh './scripts/build-docker.sh'
       }

       // Deploy Docker image to AWS for testing
       stage('Deploy') {
            echo 'Delploy to AWS'
            sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) ami-9398d3e0'
       }

       // Clean our building environment
       // This saves a little time opposed to delete everything
       stage('Cleanup') {
            echo 'prune and cleanup'
            sh 'npm prune'
            sh 'rm -rf node_modules'
            setBuildStatus("Build complete", "SUCCESS")
       }

    } catch (err) {

        // Catch any error
        currentBuild.result = "FAILURE"
        throw err

    } finally {

        // No matter what - notify on failure and provide data from unit and code coverage test
        notifyBuild(currentBuild.result)
        publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'coverage/', reportFiles: 'index.html', reportName: 'Code Coverage Report'])

        step([
            $class        : 'XUnitBuilder',
            testTimeMargin: '3000',
            thresholdMode : 1,
            thresholds    : [
                [
                    $class              : 'FailedThreshold',
                    failureNewThreshold : '',
                    failureThreshold    : '',
                    unstableNewThreshold: '',
                    unstableThreshold   : '0'
                ], [
                    $class              : 'SkippedThreshold',
                    failureNewThreshold : '',
                    failureThreshold    : '',
                    unstableNewThreshold: '',
                    unstableThreshold   : '0']
            ],
            tools         : [
                [
                    $class               : 'JUnitType',
                    deleteOutputFiles    : true,
                    failIfNotNew         : true,
                    pattern              : 'reports/*.xml',
                    skipNoTestFiles      : true,
                    stopProcessingIfError: false
                ]
            ]
        ])
    }
}


// Set build status on each commit on Github - nice yeah!
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

// Notify via Slacker on every build activity
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
