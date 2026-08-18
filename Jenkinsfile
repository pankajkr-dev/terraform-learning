pipeline {
    agent none
    stages {
        stage('Bootstrap S3 Backend') {
            agent {
                docker {
                    image 'amazon/aws-cli:latest'
                    args  '--entrypoint=""'
                }
            }
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh '''
                        BUCKET_NAME="dev-terraform-state-pankaj-2026"
                        REGION="us-east-1"

                        echo "Checking if S3 bucket $BUCKET_NAME exists..."
                        if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
                            echo "Bucket missing. Creating $BUCKET_NAME..."
                            aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
                            aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
                            echo "Bucket created and versioning enabled."
                        else
                            echo "Bucket $BUCKET_NAME already exists and is ready."
                        fi
                    '''
                }
            }
        }
        stage('Checkout') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0'
                }
            }
            steps {
                checkout scm
            }
        }
        stage('Terraform Init') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0'
                }
            }
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform init'
                }
            }
        }
        stage('Terraform Validate') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0'
                }
            }
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform validate'
                }
            }
        }
        stage('Terraform Plan') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0'
                }
            }
            steps {
                withCredentials([[ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds-for-terraform' ]]) {
                    sh 'terraform plan -var-file="dev.tfvars" -out=tfplan'
                }
            }
        }
    }
}