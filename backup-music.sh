#!/bin/bash
rsync -avzpH --partial --delete -P --progress /mnt/raid/Music bu@10.20.0.5:/home/bu/music 

