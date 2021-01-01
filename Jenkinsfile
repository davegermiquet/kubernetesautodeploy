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
          string(name: 'TASK', choices: ['deploy','destroy'], description: 'deploy/destroy')
          string(name: 'AWS_FIRST_REGION', defaultValue: 'us-east-1', description: 'First Region to Deploy')
          string(name: 'AWS_SECOND_REGION', defaultValue: 'us-west-1', description: 'Second Region to Deploy')
       }



    stages {
        stage('Create Environment for Kubernetes and Docker') {
              steps {
                    withCredentials([usernamePassword(credentialsId: 'AMAZON_CRED', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    echo 'Deploying to DEV/QA AWS INSTANCE'
                    sh "cd terraform;terraform init  -input=false"
                    sh "cd terraform;terraform ${TASK} -input=false -auto-approve"
                    sh "cd terraform;terraform apply  -input=false -auto-approve"
                    script {
                        server_deployed = sh ( script: 'terraform output kuber_master_aws_instance_public_ip', returnStdout: true).trim()
                        private_ip_deployed = sh ( script: 'terraform output kuber_node_aws_instance_private_ip', returnStdout: true).trim()
                        node_one = sh ( script: 'terraform output kuber_master_aws_instance_private_ip', returnStdout: true).trim()
                    }
                 }
              }
        }
       stage('install packages on aws instance') {
         steps {
              sh 'echo "awsserver ansible_port=22 ansible_host=${server_deployed}" > inventory_hosts'
              sh  'echo "kuber_node_1 ansible_port=2222 ansible_host=localhost" >> inventory_hosts'
              sh 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "workspace=${WORKSPACE} target=awsserver node_ip=${INSTANCE_PRIVATE_IP} kuberprivateip=${INSTANCE_PRIVATE_IP}" ${WORKSPACE}/playbooks/deploy-squid-playbook.yml'


             }
           }
        }
 }