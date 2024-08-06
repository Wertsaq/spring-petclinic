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
                    reuseNode true  
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Running Maven clean and package...'
                sh 'mvn clean package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
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

        stage('Archive Artifacts') {
            agent {
                docker {
                    image 'maven:3.9.8-eclipse-temurin-22-alpine' 
                    args '-v /var/tmp/maven:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2'
                }
            }
            steps {
                echo 'Archiving build artifacts...'
                archiveArtifacts artifacts: "target/*.jar", fingerprint: true
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
                    echo 'Deploying application...'
                    sh "docker pull ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                    sh "docker stop petclinic || true"
                    sh "docker rm petclinic || true"
                    sh "docker run -d --name petclinic -p 8081:8080 ${IMAGE_NAME}:${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    echo 'Performing health check...'
                    sh '''
                    for i in {1..10}; do
                        if curl -s http://192.168.56.122:8081/actuator/health | grep '"status":"UP"' > /dev/null; then
                            echo "Health check passed!"
                            exit 0
                        else
                            echo "Health check failed. Retrying in 5 seconds..."
                            sleep 5
                        fi
                    done
                    echo "Health check failed after 10 attempts."
                    exit 1
                    '''
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
