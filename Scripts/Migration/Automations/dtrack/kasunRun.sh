#!/bin/bash
#bash startExperiment.sh "vanilla" "memcached" "8192"
#bash startExperiment.sh "dtrack" "memcached" "12288 4096"
#bash startExperiment.sh "xbzrle-dtrack" "memcached" "16384"
bash startExperiment.sh "dtrack" "sysbench" "16384"
bash startExperiment.sh "dtrack xbzrle-dtrack" "oltp" "16384 12288"