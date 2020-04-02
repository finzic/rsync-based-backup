#!/bin/bash
rsync -avzpH --partial --delete -P --progress /mnt/raid/Foto bu@10.20.0.5:/home/bu/foto

