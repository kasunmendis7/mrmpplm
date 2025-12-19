#!/bin/bash
OPTIMIZATION="$1"
WORKLOAD="$2"
RAM=$3
VM="$4"
TAP="$5"
CORE=$6
WORKINGSET="$7"
LOG_FILE="$8"
EXPERIMENT_DIR="$9"
HASH_TYPE="${10}"

DST=163
POST="false"
IP=200 
PASSWORD="workingset"
USER="workingset"
WORKLOAD_ID=""
COUNT=0

printpara() {
	echo $OPTIMIZATION
	echo $WORKLOAD
	echo $RAM
	echo $VM
	echo $TAP
	echo $CORE
	echo $WORKINGSET
	echo $HASH_TYPE
	echo $LOG_FILE
	echo $EXPERIMENT_DIR
}

log() {
	echo $1 >> $LOG_FILE
}

terminate-qemu () {
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=60 root@10.22.196.$IP "poweroff"
	sleep 20
	ping -c 5 10.22.196.$IP > /dev/null
	PING=$?
	if [[ $PING -ne 0 ]];
	then
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pkill qemu"
	fi
	sleep 10
	pkill qemu
}

check-error() {
	if [ $2 -ne 0 ]; then
		echo ">>> $1 command failed with error code $2."
		terminate-qemu
		exit 255
	fi
}

get-migration-details() {
	MIGRATION=""

	while [[ $MIGRATION != *"completed"* ]];
	do
		if [[ $COUNT -eq 100 ]]
		then 
			echo ">>> Migration Failure"
			log ">>> Migration Failure"
			HOSTS=("162" "163")
			for HOST  in "${HOSTS[@]}"
			do
				sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$HOST "pkill qemu"
				sleep 10
			done
			exit 255
		fi
		sleep 10
		echo ">>> Checking for Migration Status"
		MIGRATION=$(bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Status/migration-status.sh)
		((COUNT++))
	done

	date +"%Y-%m-%d %H:%M:%S"
	echo ">>> Migration Completed"

	ping -c 10 10.22.196.$IP > /dev/null
	PING=$?

	if [[ $PING -eq 0 ]]; 
	then
		while true;
		do
			WORKLOAD_ID=$(sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep -f ycsb")
			if [[ -z $WORKLOAD_ID ]];
			then
				sshpass -p "$PASSWORD" rsync -e "ssh -o StrictHostKeyChecking=no" -av --progress --no-o --no-g root@10.22.196.$IP:/home/${USER}/Desktop/benchbase/target/benchbase-postgres/results/ycsb*results.csv "$EXPERIMENT_DIR"
				check-error "rsync" $?
				sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "rm /home/$USER/Desktop/benchbase/target/benchbase-postgres/results/ycsb*"
				break
			else
				echo ">>> OLTP is Still Running"
				sleep 10
			fi
		done
		log "Migration:" 
		log "$MIGRATION"      
		log ""
	else
		echo ">>> Ping Failed : VM is Not Responding after Migration"
		log ">>> Ping Failed : VM is Not Responding after Migration"
		HOSTS=("162" "163")
		for HOST  in "${HOSTS[@]}"
		do
			sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$HOST "pkill qemu"
			sleep 10
		done
		exit 255
	fi

	terminate-qemu
	exit 100
}

# Readying Destination to Recieve VM
echo ">>> Readying Destination to Recieve VM"
sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startDestination.sh $VM $TAP $RAM $CORE $POST" &
sleep 5
DESTINATION_ID=$(sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pgrep qemu")

if [[ -n $DESTINATION_ID ]];
then
	echo ">>> Successfull Started Destination"
else
	echo ">>> Destination Container Not Started"
	exit 255       
fi

# Starting the VM in Source Machine
bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Automations/vm-start/startSource.sh $VM $TAP $RAM $CORE $POST &
sleep 2m
SOURCE_ID=$(pgrep qemu)

if [[ -n $SOURCE_ID ]];
then
	echo ">>> VM Up & Running"
else
	echo ">>> VM Not Started"
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "pkill qemu"
	exit 255
fi

# Starting the Specific Workload in VM
printf ">>> Starting %s in VM\n" ${WORKLOAD^}
sleep 10

if [ "$WORKLOAD" = "oltp" ]
then
	sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "cd /home/workingset/Desktop/benchbase/target/benchbase-postgres && java -jar benchbase.jar -b ycsb -c config/postgres/ycsb_read-update_config.xml --create=true --load=true --execute=true -s 1 > /dev/null 2>&1 &" &
	sleep 10
	WORKLOAD_ID=$(sshpass -p "workingset" ssh -o StrictHostKeyChecking=no root@10.22.196.$IP "pgrep -f ycsb")
fi

if [[ -n $WORKLOAD_ID ]]; 
then
	printf ">>> Started %s in VM, Process ID : %s\n" ${WORKLOAD^} $WORKLOAD_ID
else
	printf ">>> Process %s Not Started" ${WORKLOAD^}
	terminate-qemu
	exit 255
fi

if [[ "$OPTIMIZATION" = "vanilla" ]]; 
then
	sleep 5
fi

# Trigger Migration
if [ "$OPTIMIZATION" = "compress" ] || [ "$OPTIMIZATION" = "compress-hbfdp" ] || [ "$OPTIMIZATION" = "compress-dtrack" ]
then
	sshpass -p "primedirective" ssh -o StrictHostKeyChecking=no root@10.22.196.$DST "bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Triggers/Pre-Copy/precopy-compress-dst.sh"
fi

bash /mnt/nfs/samindu/mrmpplm/Scripts/Migration/Triggers/Pre-Copy/precopy-vm-migrate.sh $OPTIMIZATION $HASH_TYPE $DST
date +"%Y-%m-%d %H:%M:%S"

# Collect Migration Data
get-migration-details
