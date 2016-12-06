#!groovy


node('node') {

    currentBuild.result = "SUCCESS"

    try {

       stage 'Checkout'

            checkout scm

       stage 'Test'

            env.NODE_ENV = "test"

            print "Environment will be : ${env.NODE_ENV}"

            sh 'node -v'
            sh 'npm prune'
            sh 'npm install'
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

            mail body: 'project build successful',
                        from: 'sveinn@jenkins.sveinng.com',
                        replyTo: 'sveinn@sveinng.com',
                        subject: 'project build successful',
                        to: 'sveinng@gmail.com'

        }


    catch (err) {

        currentBuild.result = "FAILURE"

            mail body: "project build error is here: ${env.BUILD_URL}" ,
            from: 'sveinn@jenkins.sveinng.com',
            replyTo: 'sveinn@sveinng.com',
            subject: 'project build failed',
            to: 'sveinng@gmail.com'

        throw err
    }

}
