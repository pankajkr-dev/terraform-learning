pipeline {
    agent none

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select the target deployment environment'
        )
    }

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
                    sh """
                        rm -rf .terraform
                        terraform init -input=false
                        chmod -R +x .terraform
                        terraform workspace select -or-create ${params.ENVIRONMENT}
                    """
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
                    sh """
                        chmod -R +x .terraform
                        terraform workspace select ${params.ENVIRONMENT}
                        terraform plan -input=false -var-file="${params.ENVIRONMENT}.tfvars"
                    """
                }
            }
        }

        stage('Approval') {
            agent none
            steps {
                input message: "Approve deployment to ${params.ENVIRONMENT} environment?", ok: 'Apply Changes'
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
                        terraform workspace select ${params.ENVIRONMENT}
                        terraform apply -input=false -var-file="${params.ENVIRONMENT}.tfvars" -auto-approve
                    """
                }
            }
        }
    }
}