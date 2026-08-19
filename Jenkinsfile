pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.7.0'
            args  '--entrypoint="" -u 0:0 --net=host'
        }
    }
    environment {
        TF_PLUGIN_CACHE_DIR = '/var/jenkins_home/.terraform.d/plugin-cache'
        CHECKPOINT_DISABLE  = '1'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Setup Plugin Cache') {
            steps {
                sh 'mkdir -p $TF_PLUGIN_CACHE_DIR'
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
    }
}