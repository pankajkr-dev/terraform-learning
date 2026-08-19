pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.7.0'
            // Mount the VM cache directory into /cache inside the container
            args  '--entrypoint="" -u 0:0 --net=host -v /var/jenkins_home/.terraform.d/plugin-cache:/cache'
        }
    }
    environment {
        TF_PLUGIN_CACHE_DIR = '/cache'
        CHECKPOINT_DISABLE  = '1'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Terraform Init') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform init -input=false'
                }
            }
        }
        stage('Terraform Validate') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform validate'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform plan -var-file="dev.tfvars" -out=tfplan'
                }
            }
        }
        stage('Approval') {
            steps {
                input message: 'Approve infrastructure deployment to AWS?', ok: 'Apply Changes'
            }
        }
        stage('Terraform Apply') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }
    }
}