pipeline {
    agent none

    environment {
        CHECKPOINT_DISABLE = '1'
    }

    stages {
        stage('Checkout') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh '''
                        rm -rf .terraform
                        terraform init -input=false
                        chmod -R +x .terraform
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh '''
                        chmod -R +x .terraform
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh '''
                        chmod -R +x .terraform
                        terraform plan -var-file="dev.tfvars" -out=tfplan
                    '''
                }
            }
        }

        stage('Approval') {
            agent none
            steps {
                input message: 'Approve infrastructure deployment to AWS?', ok: 'Apply Changes'
            }
        }

        stage('Terraform Apply') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh '''
                        chmod -R +x .terraform
                        terraform plan -input=false -out=tfplan
                        terraform apply -input=false tfplan
                    '''
                }
            }
        }
    }
}