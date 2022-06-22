#!/bin/bash
# set -x
### VARIABLES. 
DEST_IP=r4spi.local
SOURCE_BASE=/mnt/raid
SOURCE_FOLDER=installers
SOURCE_PATH=$SOURCE_BASE/$SOURCE_FOLDER
DEST_FOLDER=installers
SNAPSHOT_SOURCE=/mnt/storage/installers
SNAPSHOT_DEST=/mnt/storage/installers-snapshots-sv
CREATE_SNAPSHOT=$1

if [ x$CREATE_SNAPSHOT == x ]
then
	SNAPSHOT=false
else
	if [ $CREATE_SNAPSHOT == '-snap' ]
	then
		SNAPSHOT=true
		echo "Snapshot creation enabled"
	else
		SNAPSHOT=false
		echo "Snapshot creation disabled"
	fi
fi


# calculating diff md5sums
echo "Finding modified files and calculating checksums..."
rm /tmp/md5-$DEST_FOLDER.txt
cd $SOURCE_BASE
# correct if changes are present: 
# rsync -nia --out-format="%i \"%f\"" $SOURCE_FOLDER bu@$DEST_IP:/home/bu/$DEST_FOLDER | egrep '<' | cut -d' ' -f2- | xargs md5sum > /tmp/md5-$DEST_FOLDER.txt
#
# find differences and write them in a file: 
rsync -nia --out-format="%i \"%f\"" $SOURCE_FOLDER bu@$DEST_IP:/home/bu/$DEST_FOLDER | egrep '<' | cut -d' ' -f2- > /tmp/changed-files.txt
# if changed-files.txt has no lines there are no changed files, so do not do anything - the backup operation stops. 
CHANGES=$(wc -l < /tmp/changed-files.txt) 
if [ $CHANGES -eq 0 ] 
then
	echo "No changed files in $SOURCE_PATH - nothing to backup - operation completed." 
else
	echo "There are $CHANGES changed files - calculating md5sums..."
	cat /tmp/changed-files.txt | xargs md5sum > /tmp/md5-$DEST_FOLDER.txt
	echo "md5sums of modified files: "
	cat /tmp/md5-$DEST_FOLDER.txt
	# NOTABENE - check paths! 
	
	echo "rsync-ing files..."
	rsync -avzpH --partial --delete -P --progress $SOURCE_PATH bu@$DEST_IP:/home/bu/$DEST_FOLDER
	THIS=$(pwd)
	cd $SOURCE_PATH
	echo "Sending md5sums of modified files to $DEST_IP..."
	scp /tmp/md5-$DEST_FOLDER.txt bu@$DEST_IP:/tmp/

	cat << EOF > /tmp/check-md5sums.sh
#!/bin/bash
cd $DEST_FOLDER
md5sum -c /tmp/md5-$DEST_FOLDER.txt
EOF

	ssh bu@$DEST_IP "bash -s" < /tmp/check-md5sums.sh
	EXIT_CODE=$?
	echo "result = $EXIT_CODE "

	if [ $EXIT_CODE -eq 0 ]
	then
		echo "remote md5sum is correct."
		if [ $SNAPSHOT == 'true' ]
		then
	        	echo "Creating snapshot on destination"
		        ssh -t pi@$DEST_IP "sudo btrfs subvolume snapshot $SNAPSHOT_SOURCE $SNAPSHOT_DEST/$DEST_FOLDER\_$(date +%Y.%m.%d-%H.%M.%S)"
		else
			echo "No snapshot will be created."
		fi	
	else
	        echo "remote md5 check gave error code $EXIT_CODE"
	fi
	cd $THIS
	echo "Backup operation finished successfully."
fi

