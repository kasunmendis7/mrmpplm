#!/bin/bash

COMMENT=$1

cd /mnt/oldnfs/nfs/samindu/mrmpplm/Data-and-Logs/

echo ">>> Adding and Commiting to Git Remote"
git add .
git commit -m "Adding $COMMENT"
echo ">>> Fetch and Pull Git Remote"
git fetch
git pull
echo ">>> Pushing New Data"
git push
