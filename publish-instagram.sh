#!/bin/sh

. ./credentials.txt

PUBLISH=1
usage () {
echo
cat <<- EOF
Usage: $0 <OPTION>

Options:
  -d                           dry run
  -f <file>                    just publish from postqueue
  -q                           show quota usage
  -h                           shows this help

Requirements:
  credentials.txt
  imagemagick

EOF
}

quotausage () {
    curl \
        -X GET \
	"https://graph.facebook.com/${apiversion}/${IGID}/content_publishing_limit?fields=config,quota_usage,rate_limit_settings&access_token=${TOKEN}"	2>/dev/null | \
    jq .
}

publishqueue () {
    cat ${1} | while read line;
    do
        set -- $line
        echo "Image: $1 Caption $2"

        CREATIONID=$( curl -X POST "https://graph.facebook.com/${IGID}/media?image_url=${1}&caption=${2}&access_token=${TOKEN}" | jq -r .id )
        echo "CREATIONID: ${CREATIONID}"
        if [ ${CREATIONID:-} ] ; then
            curl -X POST "https://graph.facebook.com/${IGID}/media_publish?creation_id=${CREATIONID}&access_token=${TOKEN}" | jq .
        else
            echo "CREATIONID not created"
        fi
    done
}

while getopts "f:dq" opt; do
  case ${opt} in
    f) publishqueue $OPTARG
       exit 0
       ;;
    d) unset PUBLISH ;;
    q) quotausage
       exit 0
       ;;
    \?)
       usage
       exit 0
       ;;
  esac
done

rm -f docs/*
mkdir -p docs
rm -f postqueue.txt
TOPIC=$(curl -k  https://www.barbearclassico.com/index.php?board=15.0 2>/dev/null |\
       grep "span id=" | head -n1 |\
       awk -F"?topic=" '{ print $2 }' | awk -F\" '{ print $1 }')

curl -k -o "bcimages${TOPIC}.html" \
           "https://www.barbearclassico.com/index.php?action=printpage;topic=$TOPIC"

pandoc -s "bcimages${TOPIC}.html" -t rst -o "bcimages${TOPIC}.text"

latest=$(cat "bcimages${TOPIC}.text" | grep "Post by" | tail -n1)

if [ -f lastpost.txt ]; then
    lastpost=$( cat lastpost.txt )
    if [ "$latest" = "$lastpost" ] ; then
	    echo "nothing to do here"
	    exit 0
    fi
    line=$( grep -n "$lastpost" "bcimages${TOPIC}.text" | cut -f1 -d: )
#    [ ${line:-} ] && sed -i  "1,${line}d" "bcimages${TOPIC}.text"
fi 

LASTPOST=$(cat "bcimages${TOPIC}.text" | grep "Post by" | tail -n1)
awk '/^Post/{ f = sprintf("docs/doc_%04d.text", d++) } f{print > f} /^`SMF/{f=""}' "bcimages${TOPIC}.text"
sed -i '$d' docs/doc*

IMAGESDIR="${DESTINATION:-/srv/www/revive-adserver/images}"
IGIMGSOURCE="https://pub.barbearclassico.com/images"
for article in $( grep -oPi "(jpg)|(jpeg)|(png)" docs/* | cut -d: -f1) ; do
    IGCAPTION="$(cat $article | grep -Pvi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)' | \
	    sed -e '/.. raw::/,+3 d' -e 's/*//g' -e '/^$/d' -e 's/^[[:space:]]*//g' | \
	    jq -sRr @uri)"
    IMAGEURL=$(cat $article | grep -Poi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)$' | head -n1 )
    file=$(mktemp -u ${IMAGESDIR}/imageXXXXXXXX)
    newfile=$(mktemp -u igpostXXXXXXXX)
    curl -k -o "${file}" ${IMAGEURL} 2>/dev/null
    set -- $(identify -format "%w %h %m" $file)
    RATIO=$(echo "scale=2 ; ${2} * 16  / ${1}" | bc)
    EXTENSION=${3}
    if [ ${2} -gt ${1} ] ; then
        echo "it's a portrait, make it square"
        convert -background white -gravity center ${file} -resize ${2}x${2} \
		-extent ${2}x${2} "${IMAGESDIR}/${newfile}.${EXTENSION}"
	rm ${file}
    else
        if [ $(echo "$RATIO > 9" | bc -l ) -eq 1 ]; then
            echo "$file: 16x${RATIO} image is Ok for instagram"
            mv "${file}" "${IMAGESDIR}/${newfile}.${EXTENSION}"
        else
            echo "$file: image ratio is 16x ${RATIO}: IT WILL FAIL TO UPLOAD"
            # image size should be 16x9 so image height should be $1 * 9 / 16
            NEWSIZE=$(echo "${1} * 9  / 16" | bc)
            echo "we should change the image from ${1}x${2} to ${1}x${NEWSIZE}"
            convert -background white -gravity center ${file} -resize ${1}x${NEWSIZE} \
            	-extent ${1}x${NEWSIZE} "${IMAGESDIR}/${newfile}.${EXTENSION}"
            rm ${file}
        fi
    fi
    # echo "${IMAGESDIR}/$newfile.${EXTENSION}"
    chmod 666 "${IMAGESDIR}/$newfile.${EXTENSION}"
    # echo "${IGIMGSOURCE}/$newfile.${EXTENSION}"
    IGIMAGE="${IGIMGSOURCE}/$newfile.${EXTENSION}"
    echo ${IGIMAGE}
    echo "${IGIMAGE} ${IGCAPTION}" >> postqueue.txt
done

if [ ${PUBLISH:-} ] ; then
    cat postqueue.txt | while read line;
    do
        set -- $line
        echo "Image: $1 Caption $2"

        CREATIONID=$( curl -X POST "https://graph.facebook.com/${IGID}/media?image_url=${1}&caption=${2}&access_token=${TOKEN}" | jq -r .id )
        echo "CREATIONID: ${CREATIONID}"
        if [ ${CREATIONID:-} ] ; then
            curl -X POST "https://graph.facebook.com/${IGID}/media_publish?creation_id=${CREATIONID}&access_token=${TOKEN}" | jq .
        else
            echo "CREATIONID not created"
        fi
    done
    echo ${LASTPOST} > lastpost.txt
fi

