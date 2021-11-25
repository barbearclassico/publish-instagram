#!/bin/sh

. ./credentials.txt

rm -f docs/*
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
    [ ${line:-} ] && sed -i  "1,${line}d" "bcimages${TOPIC}.text"
fi 

cat "bcimages${TOPIC}.text" | grep "Post by" | tail -n1 > lastpost.txt
awk '/^Post/{ f = sprintf("docs/doc_%04d.text", d++) } f{print > f} /^`SMF/{f=""}' "bcimages${TOPIC}.text"
sed -i '$d' docs/doc*

IMAGESDIR="/srv/www/revive-adserver/images"
IGIMGSOURCE="https://pub.barbearclassico.com/images"
for article in $( grep -oPi "(jpg)|(jpeg)|(png)" docs/* | cut -d: -f1) ; do
    IGCAPTION="$(cat $article | grep -Pvi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)' | \
	    sed -e '/.. raw::/,+3 d' -e 's/*//g' -e '/^$/d' -e 's/^[[:space:]]*//g' | \
	    jq -sRr @uri)"
    IMAGEURL=$(cat $article | grep -Poi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)$' )
    file=$(mktemp ${IMAGESDIR}/imageXXXXXXXX)
    newfile=$(mktemp -u igpostXXXXXXXX)
    curl -k -o "${file}" ${IMAGEURL} 2>/dev/null
    set -- $(identify -format "%w %h %m" $file)
    RATIO=$(echo "scale=2 ; ${2} * 16  / ${1}" | bc)
    EXTENSION=${3}
    if [ $(echo "$RATIO > 9" | bc -l ) -eq 1 ]; then
        echo "$file: 16x${RATIO} image is Ok for instagram"
        mv "${file}" "${IMAGESDIR}/${newfile}.${EXTENSION}"
    else
        echo "$file: image ratio is 16x ${RATIO}: IT WILL FAIL TO UPLOAD"
        #  # assuming its not portrait
        #  # image size should be 16x9
        #  $1 - 16
        #  $2 - 9
        #  image size should be $1 * 9 / 16
        NEWSIZE=$(echo "${1} * 9  / 16" | bc)
        echo "we should change the image from ${1}x${2} to ${1}x${NEWSIZE}"
        convert -background white -gravity center ${file} -resize ${1}x${NEWSIZE} -extent ${1}x${NEWSIZE} "${IMAGESDIR}/${newfile}.${EXTENSION}"
	rm ${file}
    fi

    echo "${IMAGESDIR}/$newfile.${EXTENSION}"
    echo "${IGIMGSOURCE}/$newfile.${EXTENSION}"
    IGIMAGE="${IGIMGSOURCE}/$newfile.${EXTENSION}"
    if [ ${PUBLISH:-} ] ; then

        CREATIONID=$( curl -X POST "https://graph.facebook.com/${IGID}/media?image_url=${IGIMAGE}&caption=${IGCAPTION}&access_token=${TOKEN}" | jq -r .id )
        echo "CREATIONID: ${CREATIONID}"
        if [ ${CREATIONID:-} ] ; then
            curl -X POST "https://graph.facebook.com/${IGID}/media_publish?creation_id=${CREATIONID}&access_token=${TOKEN}" | jq .
        else
            echo "CREATIONID not created"
        fi
    fi
done


