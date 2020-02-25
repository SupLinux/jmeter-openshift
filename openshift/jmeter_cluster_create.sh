#!/usr/bin/env bash

if [ $# -lt 2 ]; then
    echo "Input parameters are not enough, please check them"
    exit 1
fi

working_dir=`pwd`

echo "checking if oc is present"

if ! hash oc 2>/dev/null
then
    echo "'oc' was not found in PATH"
    echo "Kindly ensure that you can acces an existing OpenShift cluster via oc"
    exit
fi

oc version

echo "Current list of projects on the OpenShift cluster:"

filter=$1
slave_num=$2
cpu=$3
mem=$4


echo

echo "Creating JMeter slave nodes"

echo

#oc create -f $working_dir/jmeter_slaves_deploymentconfig.yaml
oc process -f $working_dir/jmeter_slaves_dc_template.yaml -p FILTER=$filter NUMBER=$slave_num CPU=$cpu MEM=$mem | oc create -f -

#oc create -f $working_dir/jmeter_slaves_svc.yaml
oc process -f $working_dir/jmeter_slaves_svc_template.yaml -p FILTER=$filter | oc create -f -

echo "Creating JMeter Master"

#oc create -f $working_dir/jmeter_master_configmap.yaml
oc process -f $working_dir/jmeter_master_cm_template.yaml -p FILTER=$filter | oc create -f -

#oc create -f $working_dir/jmeter_master_deploymentconfig.yaml
oc process -f $working_dir/jmeter_master_dc_template.yaml -p FILTER=$filter | oc create -f -

count=0
while [ $count -lt 60 ]; do 
    sleep 3
    state=`oc get pod | grep -E "jmeter-master-$filter|jmeter-slaves-$filter" |grep "deploy"`
    if [ "$state" == "" ];then
        break
    fi
    echo "waiting for JMeter cluster ready..."
done

echo "Printout Of the $tenant Objects"

echo

oc get all -o wide

#echo project= $tenant > $working_dir/tenant_export
