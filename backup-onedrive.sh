#!/bin/bash
# set -x
### VARIABLES. 
DEST_IP=morla.local
DEST_USER=finzic
SOURCE_BASE=/mnt/c/users/lucaf/OneDrive
SOURCE_FOLDER=.
SOURCE_PATH=$SOURCE_BASE
DEST_FOLDER=OneDrive

# calculating diff md5sums
echo "Finding modified files and calculating checksums..."
rm /tmp/md5-$DEST_FOLDER.txt
cd $SOURCE_BASE
# correct if changes are present: 
# rsync -nia --out-format="%i \"%f\"" $SOURCE_FOLDER bu@$DEST_IP:/home/bu/$DEST_FOLDER | egrep '<' | cut -d' ' -f2- | xargs md5sum > /tmp/md5-$DEST_FOLDER.txt
#
# find differences and write them in a file: 
rsync -nia --exclude="\.????????-????-????-????-????????????" --out-format="%i \"%f\"" $SOURCE_FOLDER $DEST_USER@$DEST_IP:/home/$DEST_USER/$DEST_FOLDER | egrep '<' | cut -d' ' -f2- > /tmp/changed-files.txt
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
	
	echo "*******----*******"
	echo "rsync-ing files..."
	echo "*******----*******"
	rsync -avzpH --partial --delete -P --progress --exclude="\.????????-????-????-????-????????????" $SOURCE_FOLDER $DEST_USER@$DEST_IP:/home/finzic/$DEST_FOLDER
	THIS=$(pwd)
	cd $SOURCE_PATH
	echo "Sending md5sums of modified files to $DEST_IP..."
	scp /tmp/md5-$DEST_FOLDER.txt $DEST_USER@$DEST_IP:/tmp/

	cat << EOF > /tmp/check-md5sums.sh
#!/bin/bash
cd $DEST_FOLDER
md5sum -c /tmp/md5-$DEST_FOLDER.txt
EOF

	ssh $DEST_USER@$DEST_IP "bash -s" < /tmp/check-md5sums.sh
	EXIT_CODE=$?
	echo "result = $EXIT_CODE "

	if [ $EXIT_CODE -eq 0 ]
	then
		echo "remote md5sum is correct."
	else
	        echo "remote md5 check gave error code $EXIT_CODE"
	fi
	cd $THIS
	echo "Backup operation finished successfully."
fi

