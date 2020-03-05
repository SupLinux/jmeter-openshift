Jmeter Cluster Support for OpenShift

Introduction
This implementation aims to create JMeter cluster, run performane test, clean resources eventually after test finished concurrently in OpenShift. It also includes a script to generate performance test report by perfchart. Parts of scripts are on base of kubernauts/jmeter-kubernetes

Prerequisits
OpenShift version >= 3.9

N.B.: this implementation was tested on OpenShift 3.9

TL;DR
## Pipeline script example

### Operation principle

 The first script start the second script. The second script is used to start Jenkins slave pod and start perfci plug-in. In the second script, you need to download the openshift script and JMeter test script firstly. You can put JMeter script script and start perfci plug-in script in the same git repo.

Here is example of openshift script address https://github.com/zxiong/jmeter-openshift


### Geting  started:

-   First scripts
Firstly your must config 6 params in your first pipeline.

```
 OPENSHIFT_URL： Your openshift address
 PROJECT :  The place where jemter pods will run 
 TOKEN : openshift authentication token
 SLAVE_NUMBER : An interger number of jmeter slave
 CPU : jmeter slave cpu limit eg(2000m)
 MEM : jmeter slave mem limit eg(2000Mi)
```
This is the pipeline script 
``` groovy
// this is the first script example 
node {
    checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: '']], submoduleCfg: [], userRemoteConfigs: [[name: '***', url: '***']]])
    load "***"
}
```

``` groovy
// This is second script example
pipeline {
  agent {
    kubernetes {
      label "jenkins-slave-${UUID.randomUUID().toString()}"
      defaultContainer 'jnlp'
      yaml """
      apiVersion: v1
      kind: Pod
      metadata:
        labels:
          app: "my-jenkins-slave"
      spec:
        serviceAccountName: default
        containers:
        - name: jnlp
          image: docker.io/openshift/jenkins-slave-base-centos7:latest
          tty: true
          resources:
            requests:
              memory: 368Mi
              cpu: 200m
            limits:
              memory: 512Mi
              cpu: 300m
      """
    }
  }
  stages {
    stage('Build') {
      steps {
        sh "oc login ${OPENSHIFT_URL} --token=${TOKEN} -n ${PROJECT} --insecure-skip-tls-verify; oc get pods"
        script {
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[name: '', url: 'your openshift-scripts address']]]) 
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'jmx']], submoduleCfg: [], userRemoteConfigs: [[name: 'jmx', url: 'your jmeter scrpit address']]])
            performanceTesters:[Jmeter()]
          }
      }
    }
  }
}

```

- Advanced build scripts(it supports Transfer arbitary parameters 


``` groovy
// This scripts is equal to the simple build scripts and you can overwrite any number of params,  all the params are default in programme if you don't overwrite them.
pipeline {
  agent {
    kubernetes {
      label "jenkins-slave-${UUID.randomUUID().toString()}"
      defaultContainer 'jnlp'
      yaml """
      apiVersion: v1
      kind: Pod
      metadata:
        labels:
          app: "my-jenkins-slave"
      spec:
        serviceAccountName: default
        containers:
        - name: jnlp
          image: docker.io/openshift/jenkins-slave-base-centos7:latest
          tty: true
          resources:
            requests:
              memory: 368Mi
              cpu: 200m
            limits:
              memory: 512Mi
              cpu: 300m
      """
    }
  }
  stages {
    stage('Build') {
      steps {
        sh "oc login ${OPENSHIFT_URL} --token=${TOKEN} -n ${PROJECT} --insecure-skip-tls-verify; oc get pods"
        script {
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[name: 'jmeter-openshift', url: 'https://github.com/SupLinux/jmeter-openshift.git']]]) 
            checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'jmx']], submoduleCfg: [], userRemoteConfigs: [[name: 'jmx', url: 'https://github.com/SupLinux/jmx.git']]])
            performanceTestBuilder excludedTransactionPattern: '', fallbackTimezone: 'UTC', keepBuilds: 5, perfchartsCommand: "sh openshift/gen_report.sh", performanceTesters: [Jmeter(disabled: false, jmeterArgs: '', jmeterCommand: "sh $WORKSPACE/openshift/run_test.sh", jmxExcludingPattern: '', jmxIncludingPattern: 'jmx/*.jmx', noAutoJTL: false)], reportTemplate: 'perf-baseline', resultDir: 'perf-output/'
          }
      }
    }
  }
}
```
