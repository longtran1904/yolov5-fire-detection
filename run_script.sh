#!/bin/bash
batch_sizes=(120 140 160 180 200)
len=${#batch_sizes[@]}
log_file=$1
cd yolov5
rm $log_file

MAX_MEM_USAGE=0
max_memory()
{
        MAX_MEM_USAGE=0
        while true
        do
                MEMORY=$(free | awk 'NR==2{printf "%.2f", $3*100/$2 }')
                # echo "$MEMORY"
                if (($(echo "$MEMORY>$MAX_MEM_USAGE" |bc -l) )); then
                        # echo "updating MAX_MEM_USAGE"
                        MAX_MEM_USAGE=$MEMORY
                fi
                sleep 1
                trap "echo $MAX_MEM_USAGE >> $log_file; exit" SIGINT
        done
}
echo "batch_size runtime(s)" > $log_file

for ((index=0; index<$len; index++)) do
	batch_size=${batch_sizes[$index]}
	max_memory &

	START_TIME=$(date +%s)
	echo "Running....... batch size: $batch_size"
	python3 train.py --img 640 --batch $batch_size --epochs 1 --data ../fire_config.yaml --weights yolov5s.pt --workers 1 
	END_TIME=$(date +%s)
	TIME=$(($END_TIME-$START_TIME))

	kill -SIGINT $!
	wait
	echo "$batch_size $TIME" >> $log_file
done
