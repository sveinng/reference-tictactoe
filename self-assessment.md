# Self assessment
### Sveinn G. Gunnarsson - sveinng14
---

### Relevant URLs
* TicTacToe - http://tictactoe.sveinng.com/
* Jenkins - http://jenkins.sveinng.com/

---

### Scripts

List of scripts made for this project.

* scripts/build.sh
  * Builds the project into a clean directory
* scripts/build-docker.sh
  * Builds a Docker image from build directory and pushes it to Docker hub
  * Some time saving tweaks involving yarn cache
  * Verification of successful push to Docker hub
* scripts/delete-all-dockers.sh
  * Delete all tictactoe Docker images from local machine
  * Keeps Jenkins server from running out of diskspace
* scripts/install-node-modules.sh
  * Installs required node_modules based on packages.json
  * Used on Jenkins during build
* provisioning/aws_create_instance.sh
  * Automated AWS deployment
  * Deploys a test/load/production instance
  * Can deploy instance from latest git revision - or specific revision
  * Uses user-data script to fully bootstrap new instances
  * Handles verification of newly created instances
  * Handles smoketesting before assignin proper IP
  * Handles tagging of instances
* provisioning/aws_delete_instances.sh
  * Deletes all instances on AWS with given tag


### Test

* UnitTests, server logic TDD (Git commit log)
  * Yes - based on testExamples (tictactoe-game.spec.js)
* API Acceptance test - fluent API
  * Yes - (user-api.js / tictactoe.spec.js)
* Load test loop
  * Yes - (tictactoe.loadtest.js)
* UI TDD
  * Yes - but not perfect (TicCell.test.js)
* Is the game playable?
  * Yes - but not perfect


### Data migration

* Migration up and down
  * Yes - Up and down


### Jenkins

* Commit Stage (split for clarity into 3 steps)
  * Staging
    * Staging of latest code from Github
    * Prepare environment for testing and building
  * Unit Test - parallell
    * Execute unit test for server
    * Execute unit test for client
  * Build
    * Build project
    * Build docker and push to Docker hub
* Acceptance Stage - parallell
  * API Capacity (load test)
    * Deploys fresh ec2 instance on AWS and performs capacity tests
    * Delete instance when tests are done
  * API Regression
    * Deploys fresh ec2 instance on AWS and performs api regression tests
    * Delete instance when tests are done
* Deploy to production
  * Deploys fresh ec2 instance on AWS
  * Make active if it passess smoketest


### Jenkins features

* Schedule or commit hooks
  * Yes - Jenkins is triggered by push webhooks from Github
* Pipeline
  * Yes - fully automated pipeline
* Jenkins file
  * Yes - pipeline controlled with Jenkins file
* Test reports
  * Yes - Both unit test and code coverage reports
* Other
  * Yes - Github commit status reporting
* Monitoring
  * Yes - Slack notification on all build activity

### Monitoring

Datadog monitoring implemented. Instances are automatically put into monitoring during bootstrap (user-data script). All main components are monitored (docker, postgres, http). Jenkins CI server is monitored as well. Alarms are sent to projects owner by email is TicTacToe server is down or not responding to http requests.

URL to monitoring tool.
https://app.datadoghq.com/infrastructure/map



### Anything else you did to improve you deployment pipeline of the project itself?
* Running API and Loadtest in parallel
* API and Loadtest done on fresh instances which are then deleted.
* A lot of error checking and verification was built into the automated pipeline. For example check if Git-revision is valid, if Docker hub images is available and if AWS provisioning was successful.
* Since Jenkins pipeline process with Jenkinsfile presents no good method for code promotion or code back-out procedure the following workaround was created.
  * All successful builds archive the deployment artifacts on Jenkins server. These artifacts can be used to deploy the specific build to production.
  * By entering a successful build number from the main project into the TicTacToe_Manual_Deployment project - the artifacts from that specific build are executed again - effectively deploying that specific build from Docker Hub into production.
* Probably something more that I am forgetting.
