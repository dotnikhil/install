pipeline {
    agent any
    environment {
        SONAR_SCANNER = '/var/lib/jenkins/tools/hudson.plugins.sonar.SonarRunnerInstallation/sonarqube/bin/sonar-scanner' 
        SONAR_IP = 'http://'
        FIMAGE = ''
        BIMAGE = ''
        REPO = 'https://github.com/'
        DOCKERID =''
        DBYML = 'database_deployment.yml'
        FYML = 'frontend_deployment.yml'
        BYML = 'backend_deployment.yml'
    }
    stages {
        stage('git checkout') {
            steps {
                git branch: 'main', url: "${REPO}"
                echo 'Cloned the git repo'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                echo 'SonarQube Analysis'
                script {
                    withCredentials([string(credentialsId: 'sonartoken', variable: 'SONAR_TOKEN')]) {
                        withSonarQubeEnv('sonarqube') {
                            sh """${SONAR_SCANNER} \
                                -D sonar.projectVersion=v1 \
                                -D sonar.token=${SONAR_TOKEN} \
                                -D sonar.projectKey=webapp \
                                -D sonar.host.url=${SONAR_IP}"""
                        }
                    }
                }
            }
        }
        stage('docker login') {
            steps {
                withCredentials([string(credentialsId: 'dockerhubpass', variable: 'PASSWORD')]) {
                    sh "docker login -u $DOCKERID -p $PASSWORD"
                }
                echo 'Logged into DockerHub'
            }
        }
        stage('building image') {
            steps {
                echo 'Building image'
                sh "docker build -t $FIMAGE -f ./src/Web/Dockerfile ."
                sh "docker build -t $BIMAGE -f ./src/PublicApi/Dockerfile ."
            }
        }
        stage('Trivy image scanning') {
            agent {
                label 'trivy-agent'
            }
            steps {
                echo 'Scanning Images with Trivy'
                script {
                    def images = ["$FIMAGE", "$BIMAGE"]
                    def hasVulnerabilities = false
            
                    for (image in images) {
                        def sanitizedName = image.replaceAll('/', '_').replaceAll(':', '_')
                        def outputFile = "trivy_scan_results_${sanitizedName}.json"
            
                        def result = sh(
                            script: """
                                docker run --rm aquasec/trivy:latest \
                                image --format json ${image} > ${outputFile}
                            """,
                            returnStatus: true
                        )
                        echo "Trivy scan results saved to: ${outputFile}"
                        sh "cat ${outputFile}"
            
                        if (result != 0) {
                            hasVulnerabilities = true
                        }
                    }
            
                    if (hasVulnerabilities) {
                        error 'Vulnerabilities found in one or more Docker Images'
                    }
                }
            }
        }
        stage('pushing image') {
            steps {
                echo 'Pushing image to DockerHub'
                script{
                    def images = ["$FIMAGE", "$BIMAGE"]
                    for (image in images) {
                    sh "docker push ${image}"
                    }
                }
            }
        }
        stage('k8s Cluster') {
            environment {
                KUBECONFIG = '/home/config'
            }
            steps {
                echo 'Deploying pods'
                script{
                    def manifests = ["$DBYML", "$BYML", "FYML"]
                    for (manifest in manifests){
                    sh "kubectl apply -f ${manifest}"
                    }
                }
                sh 'kubectl get pods -n frontend-namespace'
                sh 'kubectl get pods -n backend-namespace'
            }
        }
    }
}
