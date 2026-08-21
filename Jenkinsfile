pipeline {
    agent none

    triggers {
        // Phase 6: Nightly drift detection schedule at 02:00 AM UTC
        cron('0 2 * * *')
        // Phase 6: Automatic GitHub Webhook trigger listener
        githubPush()
    }

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select the target deployment environment'
        )
    }

    environment {
        CHECKPOINT_DISABLE = '1'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            agent any
            steps {
                checkout scm
            }
        }

        stage('Terraform Init & Validate') {
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-deployer']]) {
                    sh """
                        rm -rf .terraform
                        terraform init -input=false
                        terraform workspace select -or-create ${params.ENVIRONMENT}
                        terraform validate
                    """
                }
            }
        }

        // WORKFLOW 1: Pull Request Plan & Native GitHub Comment
        stage('PR Automation - Terraform Plan') {
            when {
                changeRequest()
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                script {
                    // Step 1: Run Plan & generate readable text inside Terraform Container
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-deployer'], string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh """
                            terraform workspace select ${params.ENVIRONMENT}
                            terraform plan -input=false -var-file="${params.ENVIRONMENT}.tfvars" -no-color -out=tfplan.binary > plan_output.txt
                            terraform show -no-color tfplan.binary > plan_readable.txt
                        """
                    }

                    stash name: 'terraform-plan', includes: 'tfplan.binary'

                    // Step 2: Format payload natively in Groovy to avoid sed/jq/gh CLI failures
                    def rawPlan = readFile('plan_readable.txt')
                    def truncatedPlan = rawPlan.length() > 3000 ? rawPlan.substring(0, 3000) + "\n... [Output Truncated]" : rawPlan
                    def commentBody = "### 🚀 Terraform Plan Output (`${params.ENVIRONMENT}`)\n```hcl\n${truncatedPlan}\n```"
                    def jsonPayload = groovy.json.JsonOutput.toJson([body: commentBody])
                    writeFile file: 'github_payload.json', text: jsonPayload

                    // Step 3: Post comment to GitHub PR via REST API using stored token
                    withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_TOKEN')]) {
                        sh '''
                            curl -s -X POST \
                                -H "Authorization: token $GITHUB_TOKEN" \
                                -H "Accept: application/vnd.github.v3+json" \
                                -d @github_payload.json \
                                "$CHANGE_URL/comments"
                            '''
                    }
                }
            }
        }

        // WORKFLOW 2: Nightly Drift Detection & SNS Alert
        stage('Nightly Drift Detection') {
            when {
                buildingTag() == false
                expression { return currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').size() > 0 }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                script {
                    def exitCode = 0

                    // Step 1: Execute detailed-exitcode plan in Terraform container
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-deployer']]) {
                        sh 'terraform workspace select ' + params.ENVIRONMENT
                        exitCode = sh(
                            script: "terraform plan -detailed-exitcode -input=false -var-file=\"${params.ENVIRONMENT}.tfvars\" -no-color",
                            returnStatus: true
                        )
                    }

                    // Step 2: Evaluate exit code (0 = match, 2 = drift, 1 = execution error)
                    if (exitCode == 2) {
                        echo "DRIFT DETECTED: Manual infrastructure changes found in ${params.ENVIRONMENT}!"
                        currentBuild.result = 'UNSTABLE'

                        // Step 3: Publish SNS alert using AWS CLI container via Instance Profile
                        withCredentials([string(credentialsId: 'sns-topic-arn', variable: 'SNS_TOPIC_ARN')]) {
                            sh """
                                aws sns publish \
                                    --topic-arn "${SNS_TOPIC_ARN}" \
                                    --subject "ALERT: Infrastructure Drift Detected [${params.ENVIRONMENT}]" \
                                    --message "Terraform detected unmanaged console changes in environment '${params.ENVIRONMENT}' during the nightly drift check."
                            """
                        }
                    } else if (exitCode == 1) {
                        error("Terraform execution failed during drift check.")
                    } else {
                        echo "No drift detected. Infrastructure state is synchronized."
                    }
                }
            }
        }

        // WORKFLOW 3: Standard Push/Merge - Terraform Plan
        stage('Main - Terraform Plan') {
            when {
                expression {
                    return !env.CHANGE_ID && currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').isEmpty()
                }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-deployer']]) {
                    sh """
                        terraform workspace select ${params.ENVIRONMENT}
                        terraform plan -input=false -var-file="${params.ENVIRONMENT}.tfvars" -out=tfplan.binary
                    """
                }
                archiveArtifacts artifacts: 'tfplan.binary', fingerprint: true
                stash name: 'terraform-plan', includes: 'tfplan.binary', overwrite: true
            }
        }

        // WORKFLOW 3: Manual Approval Gate
        stage('Main - Approval Gate') {
            when {
                expression {
                    return !env.CHANGE_ID && currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').isEmpty()
                }
            }
            agent none
            steps {
                timeout(time: 30, unit: 'MINUTES') {
                    input message: "Approve deployment to ${params.ENVIRONMENT} environment?", ok: 'Apply Changes'
                }
            }
        }

        // WORKFLOW 3: Standard Push/Merge - Terraform Apply
        stage('Main - Terraform Apply') {
            when {
                expression {
                    return !env.CHANGE_ID && currentBuild.getBuildCauses('hudson.triggers.TimerTrigger$TimerTriggerCause').isEmpty()
                }
            }
            agent {
                docker {
                    image 'hashicorp/terraform:1.7.0'
                    args  '--entrypoint="" -u 0:0 --net=host'
                }
            }
            steps {
                unstash 'terraform-plan'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-deployer']]) {
                    sh """
                        terraform workspace select ${params.ENVIRONMENT}
                        terraform apply -input=false tfplan.binary
                    """
                }
                sh 'terraform output -raw alb_dns_name > alb_dns_name.txt'
                archiveArtifacts artifacts: 'alb_dns_name.txt', fingerprint: true
                sh 'curl --fail --retry 10 --retry-delay 15 "http://$(cat alb_dns_name.txt)"'
            }
        }
    }

    post {
        success {
            echo 'Terraform pipeline completed successfully.'
        }
        failure {
            echo 'Terraform pipeline failed.'
        }
        always {
            cleanWs()
        }
    }
}