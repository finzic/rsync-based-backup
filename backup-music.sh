#!/bin/bash
# set -x
DEST_IP=raspy
SOURCE_BASE=/mnt/raid
SOURCE_FOLDER=Music
DEST_FOLDER=music

SOURCE_PATH=$SOURCE_BASE/$SOURCE_FOLDER
SNAPSHOT_SOURCE=/mnt/storage/$DEST_FOLDER-sv
SNAPSHOT_DEST=/mnt/storage/$DEST_FOLDER-snapshots-sv
# calculating diff md5sums
echo "Finding modified files and calculating checksums..."
rm /tmp/md5-$DEST_FOLDER.txt
cd $SOURCE_BASE
rsync -nia --out-format="%i \"%f\"" $SOURCE_FOLDER bu@$DEST_IP:/home/bu/$DEST_FOLDER | egrep '<' | cut -d' ' -f2- | xargs md5sum > /tmp/md5-$DEST_FOLDER.txt
echo "md5sums of modified files: "
cat /tmp/md5-$DEST_FOLDER.txt
# NOTABENE - check paths!

echo "rsync-ing files..."
rsync -avzpH --partial --delete -P --progress $SOURCE_PATH bu@$DEST_IP:/home/bu/$DEST_FOLDER
THIS=$(pwd)
cd $SOURCE_PATH
####### rm /tmp/md5-$DEST_FOLDER.txt
####### find . -type f -exec md5sum {} >>/tmp/md5-$DEST_FOLDER.txt \;
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
        echo "Creating snapshot on destination"
        ssh -t pi@$DEST_IP "sudo btrfs subvolume snapshot $SNAPSHOT_SOURCE $SNAPSHOT_DEST/$DEST_FOLDER\_$(date +%Y.%m.%d-%H.%M.%S)"
else
        echo "remote md5 check gave error code $EXIT_CODE"
fi

echo "End of backup"
cd $THIS

