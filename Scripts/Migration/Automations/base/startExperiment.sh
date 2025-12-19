#!/bin/bash
OPTIMIZATIONS=("hbfdp-sha1")
# OPTIMIZATIONS=("hbfdp-sha1" "xbzrle-hbfdp-sha1" "hbfdp-md5" "xbzrle-hbfdp-md5" "vanilla" "xbzrle")

MAIN_FOLDER="/mnt/nfs/samindu/mrmpplm/Data-and-Logs/Experiment-Data/fake-dirty-old/"
FOLDER_DATE="$(echo $(date +%Y-%m-%d))"
FOLDER_EXP_NO=$(($(ls $MAIN_FOLDER | grep "Experiments"_"$FOLDER_DATE" | wc -l) + 1))
FOLDER="Experiments"_"$FOLDER_DATE"_"$FOLDER_EXP_NO"

mkdir $MAIN_FOLDER/$FOLDER

for OPTIMIZATION in "${OPTIMIZATIONS[@]}"
do
	ITR=${1:-1}
	EXPERIMENT=${2:-"iperf"}
	CORE=${8:-1}

	if [ "$EXPERIMENT" = "idle" ]
	then
		IMAGE="idle"
		VARIANT=${4:-1024}
		TERMINATE=${5:-8192}
		INCREMENT=${6:-1024}
		VARIANT_TYPE="ram"
	elif [ "$EXPERIMENT" = "iperf" ]
	then
		IMAGE="iperf"
		VARIANT=${4:-1024}
		TERMINATE=${5:-8192}
		INCREMENT=${6:-1024}
		VARIANT_TYPE="ram"
	elif [ "$EXPERIMENT" = "sysbench" ]
	then
		IMAGE="sysbench"
		VARIANT=${4:-1024}
		TERMINATE=${5:-8192}
		INCREMENT=${6:-1024}
		VARIANT_TYPE="ram"
	elif [ "$EXPERIMENT" = "memcached" ]
	then
		IMAGE="memcached"
		VARIANT=${4:-1024}
		TERMINATE=${5:-8192}
		INCREMENT=${6:-1024}
		VARIANT_TYPE="mcd"
		RAM=${7:-8192}
	elif [ "$EXPERIMENT" = "workingset" ]
	then
		IMAGE="workingset"
		VARIANT=${4:-50}
		TERMINATE=${5:-500}
		INCREMENT=${6:-50}
		VARIANT_TYPE="ws"
		RAM=${7:-8192}
	elif [ "$EXPERIMENT" = "oltp" ]
	then
		IMAGE="oltp"
		VARIANT=""
		VARIANT_TYPE="oltp"
		RAM=${7:-8192}
	fi

	METHODS=("tcp")
	TAP="tap0"
	VM="/mnt/nfs/samindu/vm-images/$IMAGE.img"

	DIR_NAME=""
	HASH_TYPE="sha1"

	if [ "$OPTIMIZATION" = "vanilla" ]
	then
		DIR_NAME="Vanilla_PreCopy"
	elif [ "$OPTIMIZATION" = "xbzrle" ]
	then
		DIR_NAME="XBZRLE_Enabled_Precopy"
	elif [ "$OPTIMIZATION" = "hbfdp-sha1" ]
	then
		DIR_NAME="HBFDP(SHA1)_Enabled_Precopy"
		OPTIMIZATION="hbfdp"
	elif [ "$OPTIMIZATION" = "xbzrle-hbfdp-sha1" ]
	then
		DIR_NAME="HBFDP(SHA1)_Enabled_XBZRLE_Enabled_Precopy"
		OPTIMIZATION="xbzrle-hbfdp"
	elif [ "$OPTIMIZATION" = "hbfdp-md5" ]
	then
		DIR_NAME="HBFDP(MD5)_Enabled_Precopy"
		HASH_TYPE="md5"
		OPTIMIZATION="hbfdp"
	elif [ "$OPTIMIZATION" = "xbzrle-hbfdp-md5" ]
	then
		DIR_NAME="HBFDP(MD5)_Enabled_XBZRLE_Enabled_Precopy"
		HASH_TYPE="md5"
		OPTIMIZATION="xbzrle-hbfdp"
	else 
		DIR_NAME=$OPTIMIZATION
	fi

	DATA="$MAIN_FOLDER/$FOLDER"
	DATE="$(echo $(date +%Y-%m-%d))"
	EXP_NO=$(($(ls $DATA | grep "$DIR_NAME"_"$DATE" | wc -l) + 1))
	DIR="$DIR_NAME"_"$DATE"_"$EXP_NO"

	echo ">>> Creating Directory:" $DIR
	mkdir $DATA/$DIR

	log() {
		echo $1 >> $DATA/$DIR/migration_status_${VARIANT_TYPE}${VARIANT}_cores${CORE}.log
	}

	if [ "$EXPERIMENT" = "oltp" ]
	then

		touch $DATA/$DIR/migration_status_${VARIANT_TYPE}${VARIANT}_cores${CORE}.log

		for method in "${METHODS[@]}"
		do
			if [ "$method" = "tcp" ]
			then
				log "---------------- Precopy Experiments ----------------"
			elif [ "$method" = "pp" ]
			then
				log "---------------- Postcopy Experiments ----------------"
			elif [ "$method" = "hb" ]
			then
				log "---------------- Hybrid Experiments ----------------"
			fi

			log ""

			for ((i=1;i<=ITR;i++)); do
				
				printf ">>> Experiment No: %s\n" $i
				log "Experiment No: $i"
				log ""

				bash startIteration.sh $EXPERIMENT $OPTIMIZATION $VM $TAP $RAM $CORE $method $DATA/$DIR/migration_status_${VARIANT_TYPE}${VARIANT}_cores${CORE}.log $VARIANT $DATA/$DIR/Experiment${i}/ $HASH_TYPE | tee $DATA/$DIR/output_experiment${i}.log
				# STATUS=$?
				STATUS=${PIPESTATUS[0]}                 

				echo "Status: $STATUS"

				if [[ $STATUS -eq 255 ]]
				then
					echo "Error In Experiment No: $i"
					log "Error In Experiment No: $i"
					log "Restarting Experiment No: $i"
					log ""
					((i--))
					continue
				fi

				echo ""

			done

			log "------------------------------------------------------"
			log ""

		done

		log "-----------------------------------"
		log ""

		echo ""     

	else
		while [[ $VARIANT -le $TERMINATE ]]
		do

			touch $DATA/$DIR/migration_status_${VARIANT_TYPE}${VARIANT}_cores${CORE}.log

			log ">>> ${VARIANT_TYPE^^}: $VARIANT"
			echo ">>> ${VARIANT_TYPE^^}: $VARIANT"

			mkdir $DATA/$DIR/${VARIANT_TYPE}${VARIANT}

			if [ "$EXPERIMENT" = "idle" ]
			then
				RAM=$VARIANT
			elif [ "$EXPERIMENT" = "sysbench" ]
			then
				RAM=$VARIANT
			elif [ "$EXPERIMENT" = "iperf" ]
			then
				RAM=$VARIANT
			fi

			for method in "${METHODS[@]}"
			do
				if [ "$method" = "tcp" ]
				then
					log "---------------- Precopy Experiments ----------------"
				elif [ "$method" = "pp" ]
				then
					log "---------------- Postcopy Experiments ----------------"
				elif [ "$method" = "hb" ]
				then
					log "---------------- Hybrid Experiments ----------------"
				fi

				log ""

				for ((i=1;i<=ITR;i++)); do

					log "Experiment No: $i"
					log ""

					mkdir $DATA/$DIR/${VARIANT_TYPE}${VARIANT}/Experiment${i}/

					bash startIteration.sh $EXPERIMENT $OPTIMIZATION $VM $TAP $RAM $CORE $method $DATA/$DIR/migration_status_${VARIANT_TYPE}${VARIANT}_cores${CORE}.log $VARIANT $DATA/$DIR/${VARIANT_TYPE}${VARIANT}/Experiment${i}/ | tee $DATA/$DIR/output_${VARIANT_TYPE}${VARIANT}_experiment${i}.log
					# STATUS=$?
					STATUS=${PIPESTATUS[0]}

					echo "Status: $STATUS"

					if [[ $STATUS -eq 255 ]]
					then
						rm -r $DATA/$DIR/${VARIANT_TYPE}${VARIANT}/Experiment${i}/
						echo "Error In Experiment No: $i"
						log "Error In Experiment No: $i"
						log "Restarting Experiment No: $i"
						log ""
						((i--))
						continue
					fi

					echo ""

				done

				log "------------------------------------------------------"
				log ""

			done

			log "-----------------------------------"
			log ""

			echo ""      

			((VARIANT+=$INCREMENT))
		done
	fi

	echo ">>> Changing Directory to Data-and-Logs"
	bash /mnt/nfs/samindu/mrmpplm/Data-and-Logs/Experiment-Data/sync.sh $DIR

	echo ""    

done
