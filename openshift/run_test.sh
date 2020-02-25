#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Input parameters are not enough, please check them"
    exit 1
fi

#This args are pass through perfci plugin
WORKSPACE=$1
BUILD_NUMBER=$2
TEST_SCRIPT=$3
EXTRA_PARAM=$4
SLAVES_NUM=$5
CPU=$6
MEM=$7

echo $*

#Gnerate a identifier as fileter
filter=`echo $[$(date +%s%N)/1000000]`
cd $WORKSPACE/openshift && sh jmeter_cluster_create.sh "$filter" $SLAVES_NUM $CPU $MEM

# create workspace
PERFCI_WORKING_DIR="perf-output/builds/$BUILD_NUMBER/rawdata"
mkdir -p "$WORKSPACE/$PERFCI_WORKING_DIR"

cd $WORKSPACE/openshift 
test_script_path="$WORKSPACE/$TEST_SCRIPT"
test_script_dir="$(dirname $test_script_path)"

sh start_test.sh "$TEST_SCRIPT" "$test_script_dir" "$filter" "$EXTRA_PARAM"
cp /tmp/test_result_$filter.jtl $WORKSPACE/$PERFCI_WORKING_DIR/
