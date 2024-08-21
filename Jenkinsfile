pipeline {
    agent none

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'
        
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "192.168.56.126:8081"
        NEXUS_REPOSITORY = "maven-nexus-repo"
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    stages {
        stage('Compile') {
            steps {
                node('jenkins-slave-maven-petclinic') {
                    echo 'Running Maven compile...'
                    sh 'mvn clean compile'
                }
            }
        }

        stage('Test') {
            steps {
                node('jenkins-slave-maven-petclinic') {
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
                node('jenkins-slave-maven-petclinic') {
                    echo 'Running SonarQube analysis...'
                    withSonarQubeEnv('SonarQube') {
                        sh 'mvn sonar:sonar'
                    }
                }
            }
        }

        stage('Package') {
            steps {
                node('jenkins-slave-maven-petclinic') {
                    echo 'Running Maven package...'
                    sh 'mvn package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
                }
            }
        }

        stage("Publish to Nexus Repository") {
            steps {
                node('jenkins-slave-maven-petclinic') {
                    script {
                        echo 'Reading POM file...'
                        pom = readMavenPom file: "pom.xml";
                        
                        echo 'Finding artifacts in the target directory...'
                        filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                        
                        if (filesByGlob.size() > 0) {
                            artifactPath = filesByGlob[0].path;
                            artifactExists = fileExists artifactPath;
                            
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
        }

        stage('Build Docker Image') {
            agent {
                label 'jenkins-slave-docker-petclinic'
            }
            steps {
                echo 'Building Docker image...'
                script {
                    sh 'docker build -t ${IMAGE_NAME}:latest --build-arg NEXUS_IP_PORT=192.168.56.126:8081 .'
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
