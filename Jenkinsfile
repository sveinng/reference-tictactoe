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
            sh './provisioning/aws_create_instance.sh latest $(cat build/githash.txt)'

       stage 'Cleanup'

            echo 'prune and cleanup'
            sh 'npm prune'
            sh 'rm node_modules -rf'

            slackSend channel: '#general', color: 'good', message: 'Slack Message', teamDomain: 'hgop-svenni', token: 'umbD47dpxzKNkL8XpaEe74Xx'
        }


    catch (err) {

        currentBuild.result = "FAILURE"
            slackSend channel: '#general', color: 'bad', message: "project build error is here: ${env.BUILD_URL}", teamDomain: 'hgop-svenni', token: 'umbD47dpxzKNkL8XpaEe74Xx'

        throw err
    }

}
