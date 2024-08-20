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
        stage('Clone repository') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                echo 'Cloning the repository...'
                dir('workspace') {
                    git url: 'https://github.com/Wertsaq/spring-petclinic.git', branch: 'main'
                }
            }
        }

        stage('Clean') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                echo 'Running Maven clean...'
                sh 'mvn clean'
            }
        }

        stage('Compile') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                echo 'Running Maven compile...'
                sh 'mvn compile -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
            }
        }

        stage('Test') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
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
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Package') {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
                echo 'Running Maven package...'
                sh 'mvn package -DskipTests -Dcheckstyle.skip=true -Dspring-javaformat.skip=true -Denforcer.skip=true'
            }
        }

        stage("Publish to Nexus Repository") {
            agent {
                label 'jenkins-slave-maven-petclinic'
            }
            steps {
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
