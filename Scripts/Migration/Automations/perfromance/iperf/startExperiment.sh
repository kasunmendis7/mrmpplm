#!/bin/bash
OPTIMIZATIONS=("vanilla" "dtrack" "compress-dtrack")
WORKLOAD="iperf"
RAM_SIZES=(1024 2048 4096 8192 12288 16384)
CORES=1
TAP="tap0"
LOG=""

setlog() {
	LOG=$1
}

log() {
	echo $1 >> $LOG
}

makedir() {
	DIR=$1
	DATE="$(echo $(date +%Y-%m-%d))"
	COUNT=$(($(ls $DIR | grep "$2"_"$DATE" | wc -l) + 1))
	FOLDER="$2"_"$DATE"_"$COUNT"
	NEW_DIR="$DIR/$FOLDER"
	mkdir $NEW_DIR
	echo $NEW_DIR
}

BASE_DIR=$(makedir "/mnt/nfs/samindu/mrmpplm/Data-and-Logs/Experiment-Data/v2/final" "application-overhead")
	
WORKLOAD_FOLDER=${WORKLOAD^}
echo ">>> Creating Directory:" $WORKLOAD_FOLDER
WORKLOAD_DIR=$(makedir $BASE_DIR $WORKLOAD_FOLDER)

for OPTIMIZATION in "${OPTIMIZATIONS[@]}"
do
		
	OPTIMIZATION_FOLDER=""
	HASH_TYPE=""

	if [ "$OPTIMIZATION" = "vanilla" ]
	then
		OPTIMIZATION_FOLDER="Vanilla_PreCopy"
	elif [ "$OPTIMIZATION" = "dtrack" ]
	then
		OPTIMIZATION_FOLDER="Dtrack_PreCopy"
	elif [ "$OPTIMIZATION" = "compress-dtrack" ]
	then
		OPTIMIZATION_FOLDER="Dtrack_Compress_PreCopy"
	fi

	echo ">>> Creating Directory:" $OPTIMIZATION_FOLDER
	OPTIMIZATION_DIR=$(makedir $WORKLOAD_DIR $OPTIMIZATION_FOLDER)

	for RAM in "${RAM_SIZES[@]}"
	do
		WORKINGSET=$(echo "$RAM * 0.9" | bc)
		echo ">>> Workingset Size: $WORKINGSET"

		VM="/mnt/nfs/samindu/vm-images/experiments/${WORKLOAD}.img"
		echo ">>> Copying VM Image"
		rsync -aW --progress "/mnt/nfs/samindu/vm-images/${WORKLOAD}.img" "/mnt/nfs/samindu/vm-images/experiments/${WORKLOAD}.img"

		LOG_FILE=$OPTIMIZATION_DIR/ram${RAM}.migration_status.log
		touch $LOG_FILE
		setlog $LOG_FILE

		log "---------------- $OPTIMIZATION - $WORKLOAD ----------------" $LOG_FILE
		log ">>> RAM: $RAM"
		echo ">>> RAM: $RAM"

		log "Experiment No: $i"
		log ""

		EXPERIMENT_DIR=$OPTIMIZATION_DIR/RAM${RAM}/Experiment${i}
		mkdir -p $EXPERIMENT_DIR

		bash startIteration.sh $OPTIMIZATION $WORKLOAD $RAM $VM $TAP $CORES $WORKINGSET $LOG_FILE $EXPERIMENT_DIR $HASH_TYPE | tee $EXPERIMENT_DIR/output.log
		STATUS=${PIPESTATUS[0]}

		echo "Status: $STATUS"

		if [[ $STATUS -eq 255 ]]
		then
			mv $EXPERIMENT_DIR $OPTIMIZATION_DIR/RAM${RAM}/Experiment${i}_Failed/
			echo "Error In Experiment No: $i"
			log "Error In Experiment No: $i"
			log "Restarting Experiment No: $i"
			log ""
			((i--))
		fi

		echo ""


		log "-----------------------------------"
		log ""

		echo ">>> Removing VM Image"
		rm "/mnt/nfs/samindu/vm-images/experiments/$WORKLOAD.img"

		echo ""

		echo ">>> Syncing Logs to Remote Repository Data-and-Logs"
		sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.150 "bash /mnt/oldnfs/nfs/samindu/mrmpplm/Data-and-Logs/sync.sh '${OPTIMIZATION} - ${WORKLOAD} - ${RAM}'"   
	done

	echo ">>> Sleeping for 1mins" 
	sleep 1m
	echo ""    

done
