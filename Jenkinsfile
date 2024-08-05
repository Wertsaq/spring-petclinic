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


        stage('Archive Artifacts') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine'
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                sh 'pwd'
                sh 'ls -la'
                echo 'Archiving build artifacts...'
                archiveArtifacts artifacts: "target/*.jar", fingerprint: true
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
