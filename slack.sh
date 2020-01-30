#!/bin/bash
inode=$(ls -i $1 | cut -d " " -f 1)
LBA=$(debugfs -R "stat <$inode>" $2 2> /dev/null | grep '(0' | cut -d ':' -f 2 | cut -d '-' -f1)
blocksize=$(tune2fs -l $2 | grep "Block size" | awk '{print $3}')
filesize=$(du -b $1 | awk '{print $1}')
offset=$(echo "($LBA*8)*512" | bc)
if [ $filesize -le $blocksize ];
then
	slackspace=$(echo "$blocksize-$filesize" | bc);
else
	slackspace=$(echo "$filesize-(($filesize/$blocksize)*$blocksize)" | bc);
fi
echo -e "Offset: $offset\nBlock Size: $blocksize\nInode: $inode\nFile Size: $filesize bytes\nSlackSpace no Arquivo: $slackspace bytes nao utilizados"
