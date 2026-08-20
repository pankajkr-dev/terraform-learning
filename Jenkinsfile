pipeline {
    agent none

    environment {
        CHECKPOINT_DISABLE = '1'
        TARGET_ENV         = "${env.BRANCH_NAME}"
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
                    sh """
                        rm -rf .terraform
                        terraform init -input=false
                        chmod -R +x .terraform
                        terraform workspace select -or-create ${env.TARGET_ENV}
                    """
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
                    sh """
                        chmod -R +x .terraform
                        terraform workspace select ${env.TARGET_ENV}
                        terraform plan -input=false -var-file="${env.TARGET_ENV}.tfvars"
                    """
                }
            }
        }

        stage('Approval') {
            agent none
            steps {
                input message: "Approve deployment to ${env.TARGET_ENV} environment?", ok: 'Apply Changes'
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
                    sh """
                        chmod -R +x .terraform
                        terraform workspace select ${env.TARGET_ENV}
                        terraform apply -input=false -var-file="${env.TARGET_ENV}.tfvars" -auto-approve
                    """
                }
            }
        }
    }
}