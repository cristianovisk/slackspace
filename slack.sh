#!/bin/bash

checkRoot() {
	if [ $(whoami) != "root" ];
	then
		echo Execute como ROOT;
	elif [ $(whoami) == "root" ];
	then
		execute $1 $2;
	fi
}

execute() {
	inode=$(ls -i $1 | cut -d " " -f 1)
	LBA=$(debugfs -R "stat <$inode>" $2 2> /dev/null | grep '(0' | cut -d ':' -f 2 | cut -d '-' -f1)
	blocksize=$(tune2fs -l $2 | grep "Block size" | awk '{print $3}')
	filesize=$(du -b $1 | awk '{print $1}')
	offset=$(echo "($LBA*8)*512" | bc)
	device=$2
	if [[ $filesize -le $blocksize ]];
	then
		slackspace=$(echo "$blocksize-$filesize" | bc);
	elif [[ $(echo "(((($filesize/$blocksize)*$blocksize)))" | bc) -le $filesize ]];
	then
		slackspace=$(echo "(((($filesize/$blocksize)*$blocksize))+$blocksize)-$filesize" | bc);
	else
		echo "Bad_Calc";
	fi
	offset_initslack=$(echo $offset+$filesize | bc)
	offset_finalslack=$(echo $offset_initslack+$slackspace | bc)
	echo -e "Offset: $offset\nBlock Size: $blocksize\nInode: $inode\nFile Size: $filesize bytes\nSlackSpace no Arquivo: $slackspace bytes nao utilizados\nOffset Inicial do SlackSpace: $offset_initslack\nOffset Final do SlackSpace: $offset_finalslack"
	dd if=$2 of=file.dump ibs=1 skip=$offset_initslack count=$slackspace 2> /dev/null
	echo -e "\n---\n - SlackSpace Extraido em $PWD/file.dump"
}
#sudo dd if=$file_ciphed of=$device seek=$offset_initslack obs=1
#openssl enc -k password -aes256 -base64 -e -in msg.txt -out /dev/stdout 2> /dev/null
#https://jameshfisher.com/2017/03/09/openssl-enc/
checkRoot $1 $2