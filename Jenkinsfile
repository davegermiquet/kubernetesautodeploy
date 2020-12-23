pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION      = '1'
        // Common SSH file for all amazon instances
        TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
        AWS_DEFAULT_REGION="us-east-1"
    }

    // Paramterize the variable options for deployment
    options([
        parameters([
          choice(name: 'THIRTY_BEES_VERSION', choices: ['1.1.0', '1.0.8', '1.0.7', '1.0.6'], description: 'Download Specific Version'),
          choice(name: 'LINUX_PLATFORM', choices: ['arch','fedora', 'ubuntu', 'debian', 'centos'], description: 'Install On Platform'),
          string(name: 'DOCKER_HOST', defaultValue: 'docker:2375', description: 'The docker host container name and port in format <hostname>:<port>'),
          string(name: 'DEPLOY_IMAGE', defaultValue: 'docker:2375', description: 'The Images separated by ; to deployment to kubernetes to cluster'),
          string(name: 'AWS_FIRST_REGION', defaultValue: 'us-east-1', description: 'First Region to Deploy'),
          string(name: 'AWS_SECOND_REGION', defaultValue: 'us-west-1', description: 'Second Region to Deploy')
         ])
    ])



    stages {
        stage('Create Environment or Kubernetes and Docker') {
            steps {
                continue
            }
        }
    }
}