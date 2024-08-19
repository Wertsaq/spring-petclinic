pipeline {
    agent {
        label 'jenkins-slave-maven-petclinic'
    }

    environment {
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        SONAR_USER_HOME = '/var/tmp/sonar'
        IMAGE_NAME = 'wertsaq/petclinic'

        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "${NEXUS_PROTOCOL}://192.168.56.126:8081/repository/maven-nexus-repo/"
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
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

        stage('Set Artifact Info') {
            steps {
                script {
                    env.GROUP_ID = sh(script: "mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout", returnStdout: true).trim()
                    env.ARTIFACT_ID = sh(script: "mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout", returnStdout: true).trim()
                    env.VERSION = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                    env.PACKAGING = sh(script: "mvn help:evaluate -Dexpression=project.packaging -q -DforceStdout", returnStdout: true).trim()
                }
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

        stage('Upload to Nexus') {
            steps {
                script {
                    echo "Uploading artifact target/${env.ARTIFACT_ID}-${env.VERSION}.jar to Nexus..."
                    withCredentials([usernamePassword(credentialsId: env.NEXUS_CREDENTIAL_ID, usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASSWORD')]) {
                        sh """
                            mvn deploy:deploy-file \
                                -Durl=${env.NEXUS_URL} \
                                -DrepositoryId=nexus \
                                -DgroupId=${env.GROUP_ID} \
                                -DartifactId=${env.ARTIFACT_ID} \
                                -Dversion=${env.VERSION} \
                                -Dpackaging=${env.PACKAGING} \
                                -Dfile=target/${env.ARTIFACT_ID}-${env.VERSION}.${env.PACKAGING} \
                                -DgeneratePom=true \
                                -Dusername=${env.NEXUS_USER} \
                                -Dpassword=${env.NEXUS_PASSWORD}
                        """
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
