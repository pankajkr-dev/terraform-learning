pipeline {
    agent none

    environment {
        TF_PLUGIN_CACHE_DIR = '/cache'
        CHECKPOINT_DISABLE  = '1'
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
                    args  '--entrypoint="" -u 0:0 --net=host -v /var/jenkins_home/.terraform.d/plugin-cache:/cache:z'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host -v /var/jenkins_home/.terraform.d/plugin-cache:/cache:z'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host -v /var/jenkins_home/.terraform.d/plugin-cache:/cache:z'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh 'terraform plan -var-file="dev.tfvars" -out=tfplan'
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
                    args  '--entrypoint="" -u 0:0 --net=host -v /var/jenkins_home/.terraform.d/plugin-cache:/cache:z'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform']]) {
                    sh 'terraform apply -input=false tfplan'
                }
            }
        }
    }
}