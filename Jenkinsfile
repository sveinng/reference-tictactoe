#!groovy


node {

    try {
       // Prepare build environment and run unit tests
       stage('Staging') {
            notifyBuild('STARTED')
            checkout scm
            env.NODE_ENV = "test"
            print "Testing environment will be : ${env.NODE_ENV}"
            sh 'node -v'
            sh 'npm -v'
            echo '*** Installing node_modules'
            sh 'scripts/install-node-modules.sh'
       }

       stage('Unit Test') {
            parallel (
                "Server" : {
                    echo '*** Running server unit test'
                    sh 'npm run unit'
                },
                "Client" : {
                    echo '*** Running client unit test'
                    sh 'npm --prefix ./client run unit --coverage'
                }
            )
       }


       // Build Docker images from scratch and push to Docker hub
       stage('Build') {
            sh './scripts/build.sh'
            sh './scripts/delete-all-dockers.sh'
            sh './scripts/build-docker.sh'
       }


       stage('Acceptance test') {
           parallel (
               "API regression" : {
                   echo 'Delploy to AWS - ACCEPTANCE TESTING'
                   sh './provisioning/aws_delete_instances.sh test'
                   sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) test smoke'
                   timeout(time: 10, unit: 'MINUTES') {
                       sh 'npm run apitest'
                   }
               }, 
               "API Capacity" : {
                   echo 'Delploy to AWS - LOAD TESTING'
                   sh './provisioning/aws_delete_instances.sh test'
                   sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) load smoke'
                   timeout(time: 10, unit: 'MINUTES') {
                       sh 'npm run loadtest'
                   }
               }
           )
       }


        // User input - promote to production?
        // This is a terrible solution - keep code as showcase
        //stage('promotion') {
        //    def userInput = input(
        //        id: 'userInput', message: 'Let\'s promote?', parameters: [
        //            [$class: 'TextParameterDefinition', defaultValue: 'uat', description: 'Environment', name: 'env'],
        //            [$class: 'TextParameterDefinition', defaultValue: 'prod', description: 'Target', name: 'target']
        //        ])
        //    echo ("Env: "+userInput['env'])
        //    echo ("Target: "+userInput['target'])
        //} dada


       // Deploy Docker image to AWS for load testing
       stage('Production') {
            echo 'Delploy to AWS - PRODUCTION'
            sh './provisioning/aws_create_instance.sh $(cat build/githash.txt) prod smoke'
            echo 'Create deployment artifacts and archive'
	    sh 'echo ./provisioning/aws_create_instance.sh $(cat build/githash.txt) prod smoke > deploy.sh'
            archiveArtifacts artifacts: 'deploy.sh, provisioning/aws_create_instance.sh, provisioning/template/*',
                        fingerprint: true
       }

       // Clean our building environment
       // This saves a little time opposed to delete everything
       // Should be totally wiped in production setup
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

        // Always delete images for api and load tesing - save $$$
        sh './provisioning/aws_delete_instances.sh test'
        sh './provisioning/aws_delete_instances.sh load'

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
