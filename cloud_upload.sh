#!/usr/bin/env bash
version='0.3'
settingsfile="$HOME/.cloud_settings"
logfile="$HOME/.backup/backup.log"
copycom_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycom_user=' | tail -1 |  cut -d \= -f 2-`
copycom_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycom_pass=' | tail -1 |  cut -d \= -f 2-`
copycmd_path=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycmd_path=' | tail -1 |  cut -d \= -f 2-`
yandex_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'yandex_user=' | tail -1 |  cut -d \= -f 2-`
yandex_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'yandex_pass=' | tail -1 |  cut -d \= -f 2-`
mega_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'mega_user=' | tail -1 | cut -d \= -f 2-`
mega_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'mega_pass=' | tail -1 |  cut -d \= -f 2-`
megaput_path=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'megaput_path=' | tail -1 |  cut -d \= -f 2-`
function writelog
{
	errotype='INFO_:'
	if [ "x$1" != "x0" ]
	then
	errotype='ERROR:'
	fi
	
	currenttime=`date "+%Y-%m-%d %H:%M:%S"`
	message="${currenttime}: ${errotype} ${2}"
	echo $message >> $logfile
	echo $message 
	
	
	}

function copyupload
{
			copyexec="$copycmd_path"' Cloud -username='"$copycom_user"'  -password='"$copycom_pass"' put '
			copycmd="$copyexec"' "'"${1}"'" /backups' 
			echo $copycmd | sh
			result=$?
			writelog $result "Uploaded to COPY.COM"

	}
function yandexupload
{
				shortname=`echo "$1" |  rev |  cut -d "/" -f 1 | rev`
				yandcmd="/usr/bin/davix-put --userlogin $yandex_user --userpass $yandex_pass \"${filetoupload}\" \"davs://webdav.yandex.ru/my-files/${shortname}\""
				echo $yandcmd | sh
				result=$?
				writelog $result "Uploaded to Yandex"
}			


function megaupload
{
			shortname=`echo "$1" |  rev |  cut -d "/" -f 1 | rev`
			megacmd="${megaput_path}  --disable-previews --no-ask-password -u  $mega_user -p \"$mega_pass\" --path "'"/Root/my-files/'"${shortname}"'" "'"${1}"'"'
			echo $megacmd | sh
			result=$?
			writelog $result "Uploaded to Mega"
	
	}

while [  $# -gt 0 ]; do
  case "$1" in
  -h|--help)	echo "Backup script, version $version"
		echo "     Options:"
		echo "        -u file to upload"
		echo "        -cc -- upload to copy.com"
		echo "        -cy -- upload to yandex"
		echo "        -cm -- upload to mega.co.nz"
		exit 0;;
  -u) filetoupload=$2; 
        shift ;;
  -cc) uploadcopy="1"
		;;
  -cy) uploadyand="1"
		;;
  -cm) uploadmega="1"
		;;		
  -*) echo "Unknown option \"$1\"" ;;
  *)  break ;;           
  esac
  shift 
  
done

if [ "x$filetoupload" == "x" ]
then
writelog 1 "File to upload omitted...."
exit 2
fi
	
	if [ "x$uploadcopy" == "x1" ]
	then
		copyupload  $filetoupload
	fi
	
	if [ "x$uploadyand" == "x1" ]
	then
		yandexupload  $filetoupload
	fi

	if [ "x$uploadmega" == "x1" ]
	then
		megaupload  $filetoupload
	fi


	
