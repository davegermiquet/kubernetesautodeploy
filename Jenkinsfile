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
          choice(name: 'TASK', choices: ['apply','destroy'], description: 'deploy/destroy')
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
                    script {
                        server_deployed = sh ( script: 'cd terraform;terraform output kuber_master_aws_instance_public_ip | sed "s/\\\"//g"', returnStdout: true).trim()
                        private_ip_deployed = sh ( script: 'cd terraform;terraform output kuber_master_aws_instance_private_ip | sed "s/\\\"//g"', returnStdout: true).trim()
                        node_one = sh ( script: 'cd terraform;terraform output kuber_node_aws_instance_private_ip | sed "s/\\\"//g"', returnStdout: true).trim()
                    }
                 }
              }
        }

       stage('install packages on aws instance and squid instance') {
              environment {
              SERVER_DEPLOYED="${server_deployed}"
              PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
              PRIVATE_NODE_IP="${node_one}"
              }
              when {  expression { params.TASK == 'apply' } }
         steps  {
              sh  '''
              echo "awsserver ansible_port=22 ansible_host=${SERVER_DEPLOYED}" > inventory_hosts
              ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "workspace=${WORKSPACE} target=awsserver" ${WORKSPACE}/playbooks/deploy-squid-playbook.yml
              '''
              }
           }
         stage('install kubernetes master') {
            environment {
              SERVER_DEPLOYED="${server_deployed}"
              PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
              PRIVATE_NODE_IP="${node_one}"
            }
              when {  expression { params.TASK == 'apply' } }
              steps  {
                sh  '''
                echo "awsserver ansible_port=22 ansible_host=${SERVER_DEPLOYED}" > inventory_hosts
                echo "kuber_node_1 ansible_port=2222 ansible_host=localhost" >> inventory_hosts
                mkdir -p etc/kubernetes/
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "kuburnetes_master=${PRIVATE_IP_DEPLOYED} workspace=${WORKSPACE} target=awsserver" ${WORKSPACE}/playbooks/install-kubernetes-master-playbook.yml
              '''
               }
              }
              // NODE INSTALLATION


              stage('setup ssh on kubernetes node') {
              environment {
                  SERVER_DEPLOYED="${server_deployed}"
                  PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
                  PRIVATE_NODE_IP="${node_one}"
                  CMD_TO_RUN="${cmd_to_join}"
                  TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
                  MAKEPROXY="Acquire::http::Proxy \"http://${private_ip_deployed}:3128\";\nAcquire::https::${private_ip_deployed}:3128 \"DIRECT\";"
                  HTTP_PROXY="http://${private_ip_deployed}:3128"
                 }
              when {  expression { params.TASK == 'apply' } }
              steps{
              sh '''
                echo "Setup Bastion Hosts/Squid Server for Node"
                echo $MAKEPROXY > /tmp/testfile
                scp -o "StrictHostKeyChecking=no" /tmp/testfile ubuntu@${SERVER_DEPLOYED}:/tmp/testfile
                scp -o "StrictHostKeyChecking=no" ${WORKSPACE}/scripts/autoscript.sh ubuntu@${SERVER_DEPLOYED}:/tmp/autoscript.sh
                scp -o "StrictHostKeyChecking=no" /var/jenkins_home/.ssh/id_rsa  ubuntu@${SERVER_DEPLOYED}:/home/ubuntu/.ssh/id_rsa
                ssh -l ubuntu -o "StrictHostKeyChecking=no" ${SERVER_DEPLOYED} touch /tmp/runningssh
                ssh -f -o "ExitOnForwardFailure=yes" -L 2222:${PRIVATE_NODE_IP}:22 ubuntu@${SERVER_DEPLOYED} /tmp/autoscript.sh &
                sleep 5
                scp -o "port=2222" -o "StrictHostKeyChecking=no" /var/jenkins_home/.ssh/id_rsa ubuntu@localhost:/home/ubuntu/.ssh/id_rsa
                ssh -o "port=2222" -o "StrictHostKeyChecking=no" ubuntu@localhost sudo service ssh restart
                echo "for NODE Installation"
                scp -o "port=2222" -o "StrictHostKeyChecking=no" /tmp/testfile ubuntu@localhost:/tmp/testfile
                ssh -o "port=2222" -o "StrictHostKeyChecking no" ubuntu@localhost sudo cp /tmp/testfile /etc/apt/apt.conf.d/proxy
              '''
                }
              }

              stage('install kubernetes node') {
              environment {
                    SERVER_DEPLOYED="${server_deployed}"
                    PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
                    PRIVATE_NODE_IP="${node_one}"
                    CMD_TO_RUN="${cmd_to_join}"
                    TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
                    MAKEPROXY="Acquire::http::Proxy \"http://${private_ip_deployed}:3128\";\nAcquire::https::${private_ip_deployed}:3128 \"DIRECT\";"
                    HTTP_PROXY="http://${private_ip_deployed}:3128"
              }
              when {  expression { params.TASK == 'apply' } }
              steps  {
                sh  '''
                echo "kuber_node_1 ansible_port=2222 ansible_host=localhost" >> inventory_hosts
                ssh -o "StrictHostKeyChecking=no" ubuntu@${SERVER_DEPLOYED} scp -o "StrictHostKeyChecking=no" /home/ubuntu/run_to_connect_node.sh ubuntu@${PRIVATE_NODE_IP}:/home/ubuntu/run_to_connect_node.sh
                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "http_ansible_proxy=${HTTP_PROXY} cmd_to_run=${CMD_TO_RUN} kuburnetes_master=${PRIVATE_IP_DEPLOYED} workspace=${WORKSPACE} target=kuber_node_1" ${WORKSPACE}/playbooks/install-kubernetes-node-playbook.yml
                '''
                }
               }

              stage('install addons to nodes') {
              environment {
                SERVER_DEPLOYED="${server_deployed}"
                 PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
                 PRIVATE_NODE_IP="${node_one}"
                 CMD_TO_RUN="${cmd_to_join}"
                 TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
                MAKEPROXY="Acquire::http::Proxy \"http://${private_ip_deployed}:3128\";\nAcquire::https::${private_ip_deployed}:3128 \"DIRECT\";"
                HTTP_PROXY="http://${private_ip_deployed}:3128"
              }
              when {  expression { params.TASK == 'apply' } }
              steps {
              sh '''
              ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "http_ansible_proxy=${HTTP_PROXY} cmd_to_run=${CMD_TO_RUN} kuburnetes_master=${PRIVATE_IP_DEPLOYED} workspace=${WORKSPACE} target=awsserver" ${WORKSPACE}/playbooks/install-addons-kubernetes.yml
              ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "http_ansible_proxy=${HTTP_PROXY} cmd_to_run=${CMD_TO_RUN} kuburnetes_master=${PRIVATE_IP_DEPLOYED} workspace=${WORKSPACE} target=kuber_node_1" ${WORKSPACE}/playbooks/install-addons-kubernetes.yml
              '''
                }
            }
              stage('install typha to kubernetes') {
              environment {
              SERVER_DEPLOYED="${server_deployed}"
              PRIVATE_IP_DEPLOYED="${private_ip_deployed}"
              PRIVATE_NODE_IP="${node_one}"
              CMD_TO_RUN="${cmd_to_join}"
              TF_VAR_SSH_PUB = readFile "/var/jenkins_home/.ssh/id_rsa.pub"
              MAKEPROXY="Acquire::http::Proxy \"http://${private_ip_deployed}:3128\";\nAcquire::https::${private_ip_deployed}:3128 \"DIRECT\";"
              HTTP_PROXY="http://${private_ip_deployed}:3128"
              }
              when {  expression { params.TASK == 'apply' } }
              steps {
                sh '''
                 ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -vv  -i inventory_hosts --user ubuntu --extra-vars "http_ansible_proxy=${HTTP_PROXY} cmd_to_run=${CMD_TO_RUN} kuburnetes_master=${PRIVATE_IP_DEPLOYED} workspace=${WORKSPACE} target=awsserver" ${WORKSPACE}/playbooks/install-typha-calinco-node.yml
              '''
                 }
              }
        }
 }