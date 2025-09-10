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
        }

    stage('Mutation Tests - PIT') {
      steps {
        sh 'mvn org.pitest:pitest-maven:mutationCoverage'
      }
    }

     stage('SonarQube - SAST') {
       steps {
         withSonarQubeEnv('SonarQube') {
           sh "mvn sonar:sonar \
	 	              -Dsonar.projectKey=numeric-application \
	 	              -Dsonar.host.url=http://devsecops-bloody-demo.eastus.cloudapp.azure.com:9000"
         }
         timeout(time: 2, unit: 'MINUTES') {
           script {
             waitForQualityGate abortPipeline: true
           }
         }
       }
     }

    stage('Vulnerability Scan') {
    parallel {
        stage('Dependency Scan - Maven') {
            steps {
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                    sh 'mvn -DskipTests org.owasp:dependency-check-maven:12.1.0:check -DnvdApiKey=$NVD_API_KEY'
                }
            }
            post {
                always {
                    dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
            }
        }
        stage('Trivy Scan - Docker') {
            steps {
                sh 'bash trivy-docker-image-scan.sh'
            }
        }
        stage("OPA Scan - Docker") {
            steps: {
             sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
           }
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

      post { 
        always { 
            junit 'target/surefire-reports/*.xml'
            jacoco execPattern: 'target/jacoco.exec'
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
            dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }
    }
}
