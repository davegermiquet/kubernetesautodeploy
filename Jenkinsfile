pipeline {
    agent any
    properties([
        parameters([
        choice(name: 'THIRTY_BEES_VERSION', choices: ['1.1.0', '1.0.8', '1.0.7', '1.0.6'], description: 'Download Specific Version'),
        choice(name: 'LINUX_PLATFORM', choices: ['arch','fedora', 'ubuntu', 'debian', 'centos'], description: 'Install On Platform'),
        string(name: 'DOCKER_HOST', defaultValue: 'docker:2375', description: 'The docker host container name and port in format <hostname>:<port>'),
        string(name: 'DEPLOY_IMAGE', defaultValue: 'docker:2375', description: 'The Images separated by ; to deployment to kubernetes to cluster')
    ])
    ])



    stages {
        stage('Create Environment or Kubernetes and Docker') {
            steps {

            }
        }
    }
}