pipeline {
    agent any

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'qa', 'devops'], description: 'Select the deployment environment')
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Clone repository') {
            steps {
                echo 'Cloning the repository...'
                git url: 'https://github.com/Wertsaq/spring-petclinic.git', branch: 'main'
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    reuseNode true  
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running Maven clean and package...'
                sh 'mvn clean package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
            }
            post {
                always {
                    archiveArtifacts artifacts: "target/*.jar", fingerprint: true
                }
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running Maven tests...'
                sh 'mvn test'
            }
            post {
                always {
                    echo 'Archiving JUnit test results...'
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                echo 'Tagging Docker image...'
                script {
                    sh "docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    script {
                        sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
                        sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker push ${IMAGE_NAME}:latest"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    echo "Deploying application to ${params.ENVIRONMENT} environment..."

                    def serverCredentialsId = ''
                    def portCredentialsId = ''

                    if (params.ENVIRONMENT == 'dev') {
                        serverCredentialsId = 'dev-server-address'
                        portCredentialsId = 'dev-port'
                    } else if (params.ENVIRONMENT == 'qa') {
                        serverCredentialsId = 'qa-server-address'
                        portCredentialsId = 'qa-port'
                    } else if (params.ENVIRONMENT == 'devops') {
                        serverCredentialsId = 'devops-server-address'
                        portCredentialsId = 'devops-port'
                    } else {
                        error("Unknown environment: ${params.ENVIRONMENT}")
                    }

                    env.SERVER_CREDENTIALS_ID = serverCredentialsId
                    env.PORT_CREDENTIALS_ID = portCredentialsId

                    withCredentials([string(credentialsId: serverCredentialsId, variable: 'SERVER_ADDRESS'),
                                     string(credentialsId: portCredentialsId, variable: 'PORT')]) {
                        sh "docker pull ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                        sh "docker stop petclinic || true"
                        sh "docker rm petclinic || true"
                        sh "docker run -d --name petclinic -p ${PORT}:8080 ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo 'Waiting for the application to start...'
                    sleep(time: 30, unit: 'SECONDS') 

                    withCredentials([string(credentialsId: env.SERVER_CREDENTIALS_ID, variable: 'SERVER_ADDRESS'),
                                     string(credentialsId: env.PORT_CREDENTIALS_ID, variable: 'PORT')]) {
                        def healthCheckUrl = "http://${SERVER_ADDRESS}:${PORT}/actuator/health"

                        echo "Performing health check on ${healthCheckUrl}..."
                        def statusCode = sh(
                            script: "curl -o /dev/null -s -w \"%{http_code}\" ${healthCheckUrl}",
                            returnStdout: true
                        ).trim()

                        if (statusCode == '200') {
                            echo "Health check passed with status code 200!"
                        } else {
                            echo "Health check failed with status code ${statusCode}."
                            error("Health check failed")
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up...'
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
