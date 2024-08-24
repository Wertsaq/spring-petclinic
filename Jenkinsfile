pipeline {
    agent none

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = credentials('nexus-url')
        NEXUS_REPOSITORY = "maven-nexus-repo"
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
    }

    stages {
        stage('Maven Stages') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            stages {
                stage('Clone repository') {
                    steps {
                        script {
                            echo 'Cloning the repository...'
                            checkout([$class: 'GitSCM', branches: [[name: '*/main']],
                                      doGenerateSubmoduleConfigurations: false,
                                      extensions: [],
                                      userRemoteConfigs: [[url: 'https://github.com/Wertsaq/spring-petclinic.git']]])
                        }
                    }
                }

                stage('Compile') {
                    steps {
                        script {
                            echo 'Running Maven compile...'
                            sh 'mvn clean compile'
                        }
                    }
                }

                stage('Test') {
                    steps {
                        script {
                            echo 'Running Maven tests...'
                            sh 'mvn test -Dmaven.test.failure.ignore=true'
                        }
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
                        script {
                            echo 'Running SonarQube analysis...'
                            withSonarQubeEnv('SonarQube') {
                                sh 'mvn sonar:sonar'
                            }
                        }
                    }
                }

                stage('Package') {
                    steps {
                        script {
                            echo 'Running Maven package...'
                            sh 'mvn package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
                        }
                    }
                }
            }
        }

        stage("Publish to Nexus Repository") {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                script {
                    echo 'Reading POM file...'
                    def pom = readMavenPom file: "pom.xml";
                    
                    echo 'Finding artifacts in the target directory...'
                    def filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    
                    if (filesByGlob.size() > 0) {
                        def artifactPath = filesByGlob[0].path;
                        def artifactExists = fileExists artifactPath;
                        
                        if (artifactExists) {
                            echo "*** Found artifact: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version: ${pom.version}";
                            
                            nexusArtifactUploader(
                                nexusVersion: NEXUS_VERSION,
                                protocol: NEXUS_PROTOCOL,
                                nexusUrl: NEXUS_URL,
                                groupId: pom.groupId,
                                version: pom.version,
                                repository: NEXUS_REPOSITORY,
                                credentialsId: NEXUS_CREDENTIAL_ID,
                                artifacts: [
                                    [artifactId: pom.artifactId,
                                    classifier: '',
                                    file: artifactPath,
                                    type: pom.packaging],
                                    [artifactId: pom.artifactId,
                                    classifier: '',
                                    file: "pom.xml",
                                    type: "pom"]
                                ]
                            );
                        } else {
                            error "*** File: ${artifactPath}, could not be found";
                        }
                    } else {
                        error "*** No artifacts found in the target directory";
                    }
                }
            }
        }

        stage('Build Docker Image') {
            agent {
                label 'jenkins-slave-docker-petclinic'
            }
            steps {
                script {
                    echo 'Building Docker image...'
                    sh 'docker build -t ${IMAGE_NAME}:latest --build-arg NEXUS_IP_PORT=${NEXUS_URL} .'
                }
            }
        }

        stage('Tag Docker Image') {
            agent {
                label 'jenkins-slave-docker-petclinic'
            }
            steps {
                script {
                    echo 'Tagging Docker image...'
                    pom = readMavenPom file: "pom.xml"
                    version = pom.version.replace("-SNAPSHOT", "")
                    sh "docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:${version}"
                }
            }
        }

        stage('Push Docker Image to Docker Hub') {
            agent {
                label 'jenkins-slave-docker-petclinic'
            }
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_PASS')]) {
                    script {
                        pom = readMavenPom file: "pom.xml"
                        version = pom.version.replace("-SNAPSHOT", "")
                        sh 'echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin'
                        sh "docker push ${IMAGE_NAME}:${version}"
                        sh "docker push ${IMAGE_NAME}:latest"
                    }
                }
            }
        }
    }

    post {
        always {
            node('jenkins-slave-maven-petclinic') {
                echo 'Cleaning up workspace...'
                cleanWs()
            }
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
