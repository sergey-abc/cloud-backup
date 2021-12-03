#!/usr/bin/env bash
version='0.4'
settingsfile="$HOME/.cloud_settings"
logfile="$HOME/.backup/backup.log"
tempfile="$HOME/tmp/cloud.upload.tmp"
copycom_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycom_user=' | tail -1 |  cut -d \= -f 2-`
copycom_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycom_pass=' | tail -1 |  cut -d \= -f 2-`
copycmd_path=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'copycmd_path=' | tail -1 |  cut -d \= -f 2-`
yandex_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'yandex_user=' | tail -1 |  cut -d \= -f 2-`
yandex_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'yandex_pass=' | tail -1 |  cut -d \= -f 2-`
mega_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'mega_user=' | tail -1 | cut -d \= -f 2-`
mega_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'mega_pass=' | tail -1 |  cut -d \= -f 2-`
megaput_path=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'megaput_path=' | tail -1 |  cut -d \= -f 2-`
koofr_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'koofr_user=' | tail -1 | cut -d \= -f 2-`
koofr_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'koofr_pass=' | tail -1 | cut -d \= -f 2-`
ice_user=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'ice_user=' | tail -1 | cut -d \= -f 2-`
ice_pass=`egrep -v '(^#|^\s*$|^\s*\t*#)' "$settingsfile" | grep 'ice_pass=' | tail -1 | cut -d \= -f 2-`
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
				writelog $result "\"${shortname}\" uploaded to Yandex"
}			


function megaupload
{
			shortname=`echo "$1" |  rev |  cut -d "/" -f 1 | rev`
			megacmd="${megaput_path}  --disable-previews --no-ask-password -u  $mega_user -p \"$mega_pass\" --path "'"/Root/my-files/'"${shortname}"'" "'"${1}"'"'
			echo $megacmd | sh
			result=$?
			writelog $result "\"${shortname}\" uploaded to Mega"
	
	}

function koofrupload
{
				shortname=`echo "$1" |  rev |  cut -d "/" -f 1 | rev`
				##davix does not process auth errors correctly?
				#koorfcmd="/usr/bin/davix-put --userlogin $koofr_user --userpass $koofr_pass \"${filetoupload}\" \"davs://app.koofr.net:443/dav/Koofr/my-files/${shortname}\""
				koorfcmd="curl --basic --user '${koofr_user}:${koofr_pass}' -T \"${filetoupload}\" \"https://app.koofr.net:443/dav/Koofr/my-files/${shortname}\" > \"$tempfile\" 2>&1"
				echo $koorfcmd | sh
				grep "Unauthorized" "$tempfile" >/dev/null 2>&1
				result=$?
				if [ $result = 0 ]
				then 
					writelog 1 "Error uploading \"${shortname}\" to koofr: Unauthorized"
				else
					grep -i "error" "$tempfile"  >/dev/null 2>&1
					result=$?
					if [ $result = 0 ]
					then
						writelog 2 "Error uploading \"${shortname}\" to koofr: Unknown error"
					else
						writelog 0 "\"${shortname}\" uploaded to koofr"
					fi
					
				fi
				rm -fr "$tempfile"
				
}	
function iceupload
{
				shortname=`echo "$1" |  rev |  cut -d "/" -f 1 | rev`
				#icecmd="curl --basic --user '${ice_user}:${ice_pass}' -T \"${filetoupload}\" \"https://webdav.icedrive.io/my-files/${shortname}\""
				icecmd="/usr/bin/davix-put --userlogin $ice_user --userpass $ice_pass \"${filetoupload}\" \"davs://webdav.icedrive.io/my-files/${shortname}\""
				echo $icecmd | sh
				result=$?
				writelog $result "\"${shortname}\" uploaded to icedrive"
}	
while [  $# -gt 0 ]; do
  case "$1" in
  -h|--help)	echo "Backup script, version $version"
		echo "     Options:"
		echo "        -u file to upload"
		echo "        -cc -- upload to copy.com"
		echo "        -cy -- upload to yandex"
		echo "        -cm -- upload to mega.co.nz"
		echo "        -ck -- upload to koofr"
		echo "        -ci -- upload to icedrive.net"		
		exit 0;;
  -u) filetoupload=$2; 
        shift ;;
  -cc) uploadcopy="1"
		;;
  -cy) uploadyand="1"
		;;
  -cm) uploadmega="1"
		;;		
  -ck) uploadkoofr="1"
		;;		
  -ci) uploadice="1"
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


	if [ "x$uploadkoofr" == "x1" ]
	then
		koofrupload  $filetoupload
	fi	

	if [ "x$uploadice" == "x1" ]
	then
		iceupload  $filetoupload
	fi	

