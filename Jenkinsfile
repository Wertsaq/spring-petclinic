pipeline {
    agent {
        label 'jenkins-slave-maven-petclinic'
    }

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'
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

        stage('Clean') {
            steps {
                echo 'Running Maven clean...'
                sh 'mvn clean'
            }
        }

        stage('Compile') {
            steps {
                echo 'Running Maven compile...'
                sh 'mvn compile -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
            }
        }

        stage('Test') {
            steps {
                echo 'Running Maven tests...'
                sh 'mvn test -Dmaven.test.failure.ignore=true'
            }
            post {
                always {
                    echo 'Archiving JUnit test results...'
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Package') {
            steps {
                echo 'Running Maven package...'
                sh 'mvn package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Archiving build artifacts...'
                archiveArtifacts artifacts: "target/*.jar", fingerprint: true
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
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
