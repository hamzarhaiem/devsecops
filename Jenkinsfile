pipeline {
    agent any

    stages {
        stage('Build Artifact - Maven') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archiveArtifacts artifacts: 'target/*.jar'
            }
        }

        stage('Unit Tests - JUnit and Jacoco') {
            steps {
                sh "mvn test"
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }

    stage('Mutation Tests - PIT') {
      steps {
        sh 'mvn org.pitest:pitest-maven:mutationCoverage'
      }
      post {
        always {
          // nécessite le plugin "PIT Mutation"
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
      }
    }

    stage('SonarQube - SAST') {
       steps {
         withSonarQubeEnv('SonarQube') {
           sh "mvn sonar:sonar \
	 	              -Dsonar.projectKey=numeric-application \
	 	              -Dsonar.host.url=http://devsecops-bloody-demo.eastus.cloudapp.azure.com:9000 \
                      -Dsonar.login=sqp_75ac40a8be733863b6a4615cdeab9ac47ddb6640
         }
       }
     }

    stage('Docker Build and Push') {
            steps {
                withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
                    sh 'printenv'
                    sh "docker build -t hamzarhaiem/numeric-app:${GIT_COMMIT} ."
                    sh "docker push hamzarhaiem/numeric-app:${GIT_COMMIT}"
                }
            }
        }

        stage('Kubernetes Deployment - DEV') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {
                    sh "sed -i 's#replace#hamzarhaiem/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                    sh 'kubectl apply -f k8s_deployment_service.yaml'
                }
            }
        }
    }
}
