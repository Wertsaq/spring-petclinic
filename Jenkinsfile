pipeline {
    agent any

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'
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
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running Maven clean and package...'
                sh 'mvn clean package'
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    reuseNode true  
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running Maven tests...'
                sh 'mvn test'
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    reuseNode true  
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
