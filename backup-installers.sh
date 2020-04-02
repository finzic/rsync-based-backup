#!/bin/bash
set -x 
DEST_IP=10.20.0.5
SOURCE_FOLDER=/mnt/raid/installers
DEST_FOLDER=installers
SNAPSHOT_SOURCE=/mnt/storage/installers-sv
SNAPSHOT_DEST=/mnt/storage/installers-snapshots-sv

rsync -avzpH --partial --delete -P --progress $SOURCE_FOLDER bu@$DEST_IP:/home/bu/$DEST_FOLDER
THIS=$(pwd)
cd $SOURCE_FOLDER
rm /tmp/md5-$DEST_FOLDER.txt
find . -type f -exec md5sum {} >>/tmp/md5-$DEST_FOLDER.txt \;
scp /tmp/md5-$DEST_FOLDER.txt bu@$DEST_IP:/tmp/ 

cat << EOF > /tmp/check-md5sums.sh 
#!/bin/bash
cd $DEST_FOLDER/$DEST_FOLDER
md5sum -c /tmp/md5-$DEST_FOLDER.txt 
EOF

ssh bu@$DEST_IP "bash -s" < /tmp/check-md5sums.sh 
echo "result = $?"

if [ $? -eq 0 ]
then
	echo "Creating snapshot on destination" 
	ssh -t pi@$DEST_IP "sudo btrfs subvolume snapshot $SNAPSHOT_SOURCE $SNAPSHOT_DEST/$DEST_FOLDER\_$(date +%Y.%m.%d-%H.%M.%S)"  

fi

echo "End of backup" 
cd $THIS 


