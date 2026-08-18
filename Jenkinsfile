pipeline {
    agent {
        docker {
            image 'hashicorp/terraform:1.7.0'
            args  '-u 0:0'
        }
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Terraform Init') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id' ]]) {
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Validate') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id' ]]) {
                    sh 'terraform validate'
                }
            }
        }
        stage('Terraform Plan') {
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id' ]]) {
                    sh 'terraform plan -var-file="dev.tfvars" -out=tfplan'
                }
            }
        }
    }
}