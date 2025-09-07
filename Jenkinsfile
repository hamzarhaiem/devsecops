pipeline {
  agent any

  stages {
    stage('Build Artifact - Maven') {
      steps {
        script {
          if (isUnix()) {
            sh 'mvn clean package -DskipTests=true'
          } else {
            bat 'mvn clean package -DskipTests=true'
          }
        }
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        //Test the webhook
      }
    }
  }
}
