#!/usr/bin/env bash
version='0.7'
tarcmd='/bin/tar --xz --create --verbose --verbose --file='
zipcmd='7z a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on '
outputdir="$HOME"
backuptype="tar"
filepassword="/$HOME/.filepass"
logfile="$HOME/.backup/test.log"

filemtime=""
tempfile="$HOME/.tempfilelist"
uploadops=""
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

while [  $# -gt 0 ]; do
  case "$1" in
  -h|--help)	echo "Backup script, version $version"
		echo "     Options:"
		echo "        -i input file containing directories to backup (one per line)"
		echo "        -o output directory"
		echo "        -b backup type (tar|7zip)"
		echo "        -cc -- upload to copy.com"
		echo "        -cy -- upload to yandex"
		echo "        -cm -- upload to mega"
		echo "        -d n only add files changed sinse last n days" 
	
		exit 0;;
  -i) backupfile=$2; 
        shift ;;
  -cc) uploadcopy="1"
		uploadops="$uploadops -cc"
		;;
  -cy) uploadyand="1"
		uploadops="$uploadops -cy"
		;;
  -cm) uploadmega="1"
		uploadops="$uploadops -cm"
		;;		
  -o) outputdir=$2; 
        shift;;
  -b) backuptype=$2;
		shift;;
  -d) filemtime=$2;
		shift;;

		
  -*) echo "Unknown option \"$1\"" ;;
  *)  break ;;           
  esac
  shift 
  
done

if [ "x$backupfile" == "x" ]
then
echo "Error: backup list omitted...."
exit 2
fi

if [ "x$backuptype" == "x7zip" ]
then
	backuptype="zip"
else
	if [ "x$backuptype" == "xzip" ]
	then 
	backuptype="zip"
	else
		if [ "x$backuptype" == "xtar" ]
		then
			backuptype="tar"
		else
			echo "Unknown backup type. Assuming tar"
			backuptype="tar"
		fi
	fi

fi

if [ "x$backuptype" == "xtar" ]
then
exten='.tar.xz'
else
exten='.7z'
fi


if [ "x$uploadops" = "x" ]
then 
	skipupload = 2
fi

dirnow=`pwd`
numberoflines=`wc -l $backupfile | xargs -n 1 2>/dev/null | head -1 2>/dev/null`
currentlinenumber=1
while [ $currentlinenumber -le $numberoflines ]
do
	skipupload=0
	emptyarchive=0
	backupdate=`date +%Y-%m-%d__%H_%M`
	echo A1
	pwd
	backupline=`cat $backupfile | head -$currentlinenumber | tail -1`
	if [ "x$backupline" != "x" ] 
	then
		
		if ! [ -d "${outputdir}" ]
		then
		mkdir -p "${outputdir}"
		fi
		writelog 0 "==================="
		writelog 0 "<${backupline}>"
		currentdir=`echo "$backupline" |  rev |  cut -d "/" -f 1 | rev`
		rootdir=`echo "$backupline" |  rev |  cut -d "/" -f 2- | rev`
		fistchar=`echo $currentdir | cut -c1`
		if [ "$fistchar" = "." ]
		then
			echo "Replacing dot..."
			archivename=`echo $currentdir | cut -c2-`
			archivename="_${archivename}"
		else
			archivename=$currentdir
		fi
		if [ "x$filemtime" = "x" ]
		then
			writelog 0  "Full archive"
			fullarchivename="${outputdir}/${archivename}_${backupdate}${exten}"
			cryptedname="${outputdir}/${archivename}_${backupdate}.dat"
			if [ "x$backuptype" == "xtar" ]
			then
			archcmd="cd \"${rootdir}\"; ${tarcmd}"'"'"${fullarchivename}"'" "'"${currentdir}"'"'
			fi
			if [ "x$backuptype" == "xzip" ]
			then
			archcmd="cd \"${rootdir}\"; ${zipcmd}"'"'"${fullarchivename}"'" "'"${currentdir}"'"'
			fi
			writelog 0 "Archive name: ${fullarchivename}"
			#cd $rootdir
			echo $backupdate >> "$backupline/timestamp.txt"
			echo $archcmd | sh
			result=$?
			writelog $result "Archived"
		else
			writelog 0  "Diff archive, $filemtime days"
			#cd "$rootdir"
			fullarchivename="${outputdir}/${archivename}_${backupdate}_DIFF-${filemtime}.cpio.xz"
			cryptedname="${outputdir}/${archivename}_${backupdate}_DIFF-${filemtime}.dat"
			echo $backupdate >> "${rootdir}/${currentdir}/timestamp.txt"
			echo "backupdate $backupdate"
			echo "currentdir $currentdir"
			ppp=`pwd`
			echo "pwd $ppp"
			echo "Diff archive, $filemtime days" >> "$rootdir/$currentdir/timestamp.txt"
			filemtimemin=`expr  $filemtime \* 1440`
			filecountcmd="cd \"$rootdir\"; find  \"./$currentdir\" -type f -cmin -$filemtimemin > $tempfile"
			echo $filecountcmd | sh
			echo B3_
			tempfilelines=`cat $tempfile | grep -v "$currentdir/timestamp.txt" | wc -l | cut -d " " -f 1`
			if [ "x$tempfilelines" = "x0" ]
			then
			 writelog 0  "Dir: $currentdir, diff archive is empty, skipping"
			 skipupload=1
			 emptyarchive=1
			else
			 archcmd="cd \"$rootdir\"; find  \"./$currentdir\" -cmin -$filemtimemin > $tempfile"
			 echo $archcmd | sh
			 archcmd='XZ_OPT="-9"'" cd \"$rootdir\"; cat $tempfile | cpio -ov |  xz --stdout > "'"'"$fullarchivename"'"'
			 echo $archcmd | sh
			fi
			rm -fr $tempfile
		fi

		
		if [ $emptyarchive -eq 0 ]
		then

			sslcmd='openssl enc -e -aes-256-cbc -salt -k "'`cat $filepassword | head -1`'" -in  "'"$fullarchivename"'" -out  "'"$cryptedname"'"'
			echo $sslcmd | sh
			result=$?
			writelog $result "Encrypted ${cryptedname}"
			rm -fr "$fullarchivename"
			result=$?
			writelog $result "Archive deleted ($fullarchivename)"
		fi
		if [ $skipupload -eq 0 ]
		then

			pushd . > /dev/null
			SCRIPT_PATH="${BASH_SOURCE[0]}";
			if ([ -h "${SCRIPT_PATH}" ]) then
				while([ -h "${SCRIPT_PATH}" ]) do cd `dirname "$SCRIPT_PATH"`; SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
			fi
			cd `dirname ${SCRIPT_PATH}` > /dev/null
			SCRIPT_PATH=`pwd`;
			popd  > /dev/null
			uploadcmd="${SCRIPT_PATH}/cloud_upload.sh"' -u '"${cryptedname}"' '"$uploadops"
			echo $uploadcmd | bash
			rm -fr "$currentdir/timestamp.txt"
			writelog $result "____"
			cd $dirnow
		fi
	fi
	currentlinenumber=`expr $currentlinenumber + 1`
done 

