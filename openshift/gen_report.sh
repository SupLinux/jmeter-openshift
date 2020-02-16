#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Please input parameters are not enough, please check them"
    exit 1
fi
echo "1111111111"
WORKSPACE=$1
BUILD_NUMBER=$2

cd $WORKSPACE/openshift

# depoly perfchart which uses to generate test report
filter=`date +%s`
# fileter="1581824008"
oc process -f perfchart_dc_template.yaml -p FILTER=$filter | oc create -f -

# check if pod is running 
count=0
while [ $count -lt 60 ]; do
    state=`oc get pod | grep "perfchart-$filter" |grep -v "depoy" |awk '{print $3}'`
    if [ "$state" == "Running" ];then
        break
    fi
    echo "waiting for report-engine ready..."
    sleep 3 
done
echo "2222222222222"

# copy test results to perfchart pod
perfchart_pod=`oc get pod  | grep "perfchart-$filter" | awk '{print $1}'`
oc cp $WORKSPACE/perf-output/builds/$BUILD_NUMBER/rawdata/*.jtl $perfchart_pod:/tmp/

echo "123456789"
#generate test report
oc exec -ti $perfchart_pod -- perfcharts gen perf-general -d /tmp/report -o /tmp/report/mono_report.html -z UTC /tmp/

#copy reports back
echo "copy reports back"
ls
oc rsync $perfchart_pod:/tmp/report $WORKSPACE/perf-output/builds/$BUILD_NUMBER/
pwd 
ls $WORKSPACE/perf-output/builds/$BUILD_NUMBER/
#clean all pods
# oc delete all -l jmeter_report="perfchart-$filter"
