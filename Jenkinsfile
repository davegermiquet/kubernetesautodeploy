pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION      = '1'
        // Common SSH file for all amazon instances
        // SSH key for jenkins system for public key should be located below for copying to Amazon Platforms
        TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
        AWS_DEFAULT_REGION="us-east-1"
    }

    // Paramterize the variable options for deployment
        parameters {
          choice(name: 'LINUX_PLATFORM', choices: ['arch','fedora', 'ubuntu', 'debian', 'centos'], description: 'Install On Platform')
          string(name: 'DOCKER_HOST', defaultValue: 'docker:2375', description: 'The docker host container name and port in format <hostname>:<port>')
          string(name: 'DEPLOY_IMAGE', defaultValue: 'qledger;postgresql', description: 'The Images separated by ; to deployment to kubernetes to cluster')
          string(name: 'AWS_FIRST_REGION', defaultValue: 'us-east-1', description: 'First Region to Deploy')
          string(name: 'AWS_SECOND_REGION', defaultValue: 'us-west-1', description: 'Second Region to Deploy')
       }



    stages {
        stage('Create Environment or Kubernetes and Docker') {
            steps {
              echo "TODO implement steps"
            }
        }
    }
}