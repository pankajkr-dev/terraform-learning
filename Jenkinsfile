pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.7.0'
            args  '--entrypoint="" -u 0:0'
        }
    }
    environment {
        // Stores downloaded providers persistently inside Jenkins storage
        TF_PLUGIN_CACHE_DIR = '/var/jenkins_home/.terraform.d/plugin-cache'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Setup Plugin Cache') {
            steps {
                // Ensures the cache directory exists inside the container
                sh 'mkdir -p $TF_PLUGIN_CACHE_DIR'
            }
        }
        stage('Terraform Init') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform init'
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