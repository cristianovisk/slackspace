#!/bin/bash

checkRoot() {
        if [ $(whoami) != "root" ];
        then
                echo Execute como ROOT;
                exit
        elif [ $(whoami) == "root" ];
        then
               echo "ROOT CHECKED";
        fi
}

calcSlack() {
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
        if [[ $3 -eq "0" ]];
        then
                echo -e "Offset: $offset\nBlock Size: $blocksize\nInode: $inode\nFile Size: $filesize bytes\nSlackSpace no Arquivo: $slackspace bytes nao utilizados\nOffset Inicial do SlackSpace: $offset_initslack\nOffset Final do SlackSpace: $offset_finalslack"
        else
                echo "$offset_initslack:$slackspace:$offset"
        fi
        #dd if=$2 of=file.dump ibs=1 skip=$offset_initslack count=$slackspace 2> /dev/null
}

insertInSlack() {
        data=$(calcSlack $1 $2 1)
        slackspace=$(echo $data | cut -d ':' -f 2)
        offset_initslack=$(echo $data | cut -d ':' -f 1)
        file=$3
        device=$2
        filesize=$(du -b $file | awk '{print $1}')
        if [[ $filesize -gt $slackspace ]];then echo "ARQUIVO MAIOR QUE O SLACKSPACE DISPONIVEL" && exit;fi
        echo "INSERINDO ARQUIVO NO SLACKSPACE..."
        dd if=$file of=$device seek=$offset_initslack obs=1
}

dumpInSlack() {
        data=$(calcSlack $1 $2 1)
        offset_initslack=$(echo $data | cut -d ':' -f 1)
        slackspace=$(echo $data | cut -d ':' -f 2)
        echo -e "\n---\n - SlackSpace Extraido em $PWD/file.dump"
        #echo "$offset_initslack $slackspace"
        dd if=$2 of=file.dump ibs=1 skip=$offset_initslack count=$slackspace 2> /dev/null
}
#sudo dd if=$file_ciphed of=$device seek=$offset_initslacik obs=1
#
showHex(){
        data=$(calcSlack $1 $2 1)
        offset=$(echo $data | cut -d ':' -f 3)
        hd -s $offset $2 | head
}

args() {
        checkRoot
        if [ $1 == '--calc' ];then calcSlack $2 $3 0;fi
        if [ $1 == '--dump' ];then dumpInSlack $2 $3 $4;fi
        if [ $1 == '--hexdump' ];then showHex $2 $3 $4;fi
        if [ $1 == '--insert' ];then insertInSlack $2 $3 $4;fi
        if [ $1 == '--help' ];
        then
                echo -e "--calc \t\t- 'slack.sh --calc file_with_slack.txt /dev/sda1'"
                echo -e "--dump \t\t- 'slack.sh --dump file_with_slack.txt /dev/sda1'"
                echo -e "--insert \t- 'slack.sh --insert file_with_slack.txt /dev/sda1 file_to_hide_in_slackspace.txt'"
                echo -e "--help \t\t- 'This screen'"
        fi
}

#checkRoot $@
args $@
#calcSlack $2 $3 $4
