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
                git url: 'https://github.com/Wertsaq/spring-petclinic.git', branch: 'main'
            }
        }


        stage('Checkout') {
            steps {
                checkout scm
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
                script {
                    sh 'mvn clean package '
                }
            }
        }

        stage('Archive Artifacts') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                archiveArtifacts artifacts: "target/*.jar", fingerprint: true
            }
        }

        stage('SonarQube analysis') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh 'mvn sonar:sonar -Dsonar.login=$SONAR_TOKEN'
                    }
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
                script {
                    sh 'mvn test'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:latest ."
                }
            }
        }

        stage('Tag Docker Image') {
            steps {
                script {
                    sh "docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    script {
                        sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
                        sh "docker push ${IMAGE_NAME}:latest"
                        sh "docker push ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    }
                }
            }
        }
    }
}
