#!/bin/bash
OPTIMIZATIONS=("vanilla")
#OPTIMIZATIONS=("xbzrle"  "compress" "hbfdp-sha1"  "hbfdp-md5" "hbfdp-murmur3" "xbzrle-hbfdp-sha1" "xbzrle-hbfdp-md5" "xbzrle-hbfdp-murmur3" "compress-hbfdp-sha1" "compress-hbfdp-md5" "compress-hbfdp-murmur3")
WORKLOADS=("memcached")
#RAM_SIZES=(1024 2048 4096 8192 12288 16384)
RAM_SIZES=(1024)
ITERATIONS=1
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

BASE_DIR=$(makedir "/mnt/nfs/samindu/mrmpplm/Data-and-Logs/Experiment-Data" "dtrack")

for WORKLOAD in "${WORKLOADS[@]}"
do

	for OPTIMIZATION in "${OPTIMIZATIONS[@]}"
	do
		
		OPTIMIZATION_FOLDER=""
		HASH_TYPE=""

		if [ "$OPTIMIZATION" = "vanilla" ]
		then
			OPTIMIZATION_FOLDER="Vanilla_PreCopy"
		elif [ "$OPTIMIZATION" = "xbzrle" ]
		then
			OPTIMIZATION_FOLDER="XBZRLE_PreCopy"
		elif [ "$OPTIMIZATION" = "compress" ]
		then
			OPTIMIZATION_FOLDER="Compress_PreCopy"
		elif [ "$OPTIMIZATION" = "hbfdp-sha1" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_PreCopy.SHA1"
			HASH_TYPE="sha1"
			OPTIMIZATION="hbfdp"
		elif [ "$OPTIMIZATION" = "xbzrle-hbfdp-sha1" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_XBZRLE_PreCopy.SHA1"
			HASH_TYPE="sha1"
			OPTIMIZATION="xbzrle-hbfdp"
		elif [ "$OPTIMIZATION" = "compress-hbfdp-sha1" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_Compress_PreCopy.SHA1"
			HASH_TYPE="sha1"
			OPTIMIZATION="compress-hbfdp"
		elif [ "$OPTIMIZATION" = "hbfdp-md5" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_PreCopy.MD5"
			HASH_TYPE="md5"
			OPTIMIZATION="hbfdp"
		elif [ "$OPTIMIZATION" = "xbzrle-hbfdp-md5" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_XBZRLE_PreCopy.MD5"
			HASH_TYPE="md5"
			OPTIMIZATION="xbzrle-hbfdp"
		elif [ "$OPTIMIZATION" = "compress-hbfdp-md5" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_Compress_PreCopy.MD5"
			HASH_TYPE="md5"
			OPTIMIZATION="compress-hbfdp"
		elif [ "$OPTIMIZATION" = "hbfdp-murmur3" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_PreCopy.Murmur3"
			HASH_TYPE="murmur3"
			OPTIMIZATION="hbfdp"
		elif [ "$OPTIMIZATION" = "xbzrle-hbfdp-murmur3" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_XBZRLE_PreCopy.Murmur3"
			HASH_TYPE="murmur3"
			OPTIMIZATION="xbzrle-hbfdp"
		elif [ "$OPTIMIZATION" = "compress-hbfdp-murmur3" ]
		then
			OPTIMIZATION_FOLDER="HBFDP_Compress_PreCopy.Murmur3"
			HASH_TYPE="murmur3"
			OPTIMIZATION="compress-hbfdp"
		else 
			OPTIMIZATION_FOLDER=$OPTIMIZATION
		fi

		echo ">>> Creating Directory:" $OPTIMIZATION_FOLDER
		OPTIMIZATION_DIR=$(makedir $BASE_DIR $OPTIMIZATION_FOLDER)

		VM="/mnt/nfs/samindu/vm-images/$WORKLOAD.img"

		WORKLOAD_FOLDER=${WORKLOAD^}
		echo ">>> Creating Directory:" $WORKLOAD_FOLDER
		WORKLOAD_DIR=$(makedir $OPTIMIZATION_DIR $WORKLOAD_FOLDER)

		for RAM in "${RAM_SIZES[@]}"
		do
			WORKINGSET=$(echo "$RAM * 0.9" | bc)
			echo ">>> Workingset Size: $WORKINGSET"

			if [ "$WORKLOAD" != "quicksort" ]
			then
				VM="/mnt/nfs/samindu/vm-images/experiments/$WORKLOAD.img"
				echo ">>> Copying VM Image"
				#rsync -av --progress "/mnt/nfs/samindu/vm-images/$WORKLOAD.img" "/mnt/nfs/samindu/vm-images/experiments/$WORKLOAD.img"
			fi

			LOG_FILE=$WORKLOAD_DIR/ram${RAM}.migration_status.log
			touch $LOG_FILE
			setlog $LOG_FILE

			log "---------------- $OPTIMIZATION - $WORKLOAD ----------------" $LOG_FILE
			log ">>> RAM: $RAM"
			echo ">>> RAM: $RAM"

			for ((i=1;i<=ITERATIONS;i++)); do

				log "Experiment No: $i"
				log ""

				EXPERIMENT_DIR=$WORKLOAD_DIR/RAM${RAM}/Experiment${i}/
				mkdir -p $EXPERIMENT_DIR

				bash startIteration.sh $OPTIMIZATION $WORKLOAD $RAM $VM $TAP $CORES $WORKINGSET $LOG_FILE $EXPERIMENT_DIR $HASH_TYPE | tee $EXPERIMENT_DIR/output.log
				STATUS=${PIPESTATUS[0]}

				echo "Status: $STATUS"

				if [[ $STATUS -eq 255 ]]
				then
					mv $EXPERIMENT_DIR $WORKLOAD_DIR/RAM${RAM}/Experiment${i}_Failed/
					echo "Error In Experiment No: $i"
					log "Error In Experiment No: $i"
					log "Restarting Experiment No: $i"
					log ""
					((i--))
				fi

				echo ""

			done


			log "-----------------------------------"
			log ""

			if [ "$WORKLOAD" != "quicksort" ]
			then
				echo ">>> Removing VM Image"
				#rm "/mnt/nfs/samindu/vm-images/experiments/$WORKLOAD.img"
			fi

			echo ""      

		done

		echo ">>> Syncing Logs to Remote Repository Data-and-Logs"
		sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.150 "bash /mnt/nfs/samindu/mrmpplm/Data-and-Logs/sync.sh "$OPTIMIZATION - $WORKLOAD""
		
		echo ">>> Sleeping for 15mins" 
		sleep 15m
		echo ""    

	done

done
