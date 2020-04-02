#!/bin/bash
rsync -avzpH --partial --delete -P --progress /mnt/raid/Video bu@10.20.0.5:/home/bu/video

