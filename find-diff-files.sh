#!/bin/bash
#rsync -nia /mnt/raid/Documents bu@10.20.0.5:/home/bu/documents | egrep '<' | awk '{print $2}' > /tmp/diff.txt
#rsync -nia /mnt/raid/Music bu@10.20.0.5:/home/bu/music | egrep '<' | awk '{print $2}' > /tmp/diff.txt
#rsync -azh --dry-run --delete-after --out-format="[%t]:%o:%f:Last Modified %M" /mnt/raid/Music bu@10.20.0.5:/home/bu/music

rsync -nia --out-format="%i \"/%f\"" /mnt/raid/Music bu@10.20.0.5:/home/bu/music | egrep '<' | cut -d' ' -f2- > /tmp/diff.txt
echo "Diff found:"
cat /tmp/diff.txt
echo "calculating MD5 of modified files..."
xargs -a /tmp/diff.txt  md5sum > /tmp/md5sum.txt
echo "Diff found: "
cat /tmp/md5sum.txt
 



