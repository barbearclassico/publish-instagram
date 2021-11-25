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

for file in $( grep -oPi "(jpg)|(jpeg)|(png)" docs/* | cut -d: -f1) ; do
    CAPTION="$(cat $file | grep -Pvi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)'| jq -sRr @uri)"
    IMAGEURL=$(cat $file | grep -Poi 'http[s]*://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)$' )
    echo "creating: for $file:"
#   echo " CAPTION: ${CAPTION}"
#   echo " IMAGEURL: ${IMAGEURL}"

    CREATIONID=$( curl -X POST "https://graph.facebook.com/${IGID}/media?image_url=${IMAGEURL}&caption=${CAPTION}&access_token=${TOKEN}" | jq -r .id )

    echo "CREATIONID: ${CREATIONID}"
    if [ ${CREATIONID:-} ] ; then
        curl -X POST "https://graph.facebook.com/${IGID}/media_publish?creation_id=${CREATIONID}&access_token=${TOKEN}" | jq .
    else
        echo "CREATIONID not created"
    fi

done



exit 0


lastpost=$( cat bcimages2.text | grep -n "Post by" | tail -n1 )
firstpost=$( cat bcimages2.text | grep -n "Post by" | head -n1 )
# cat bcimages2.text | grep -n "Post by" | tail -n1
# 366:Post by: LATHERÃO on NOVEMBER 19, 2021, 12:28:09 PM

# is this the firstpost?
#  publish post

# get_new_file ()
# if [ lastpostnewfile = lastpost ]; then
#    exit
# else
#    getposts
# 

# awk '/^Post/{f="doc."++d} f{print > f} /^SMF/{f=""}' bcimages2.text
awk '/^Post/{ f = sprintf("docs/doc_%04d.text", d++) } f{print > f} /^SMF/{f=""}' bcimages-test002.text 


# delete last 2 lines
sed -i '$d' docs/doc* ; sed -i '$d' docs/doc*

#  now publish one per doc file:
for article in docs/* ; do 
	

done

for file in docs do:

    PRECAPTION="$(cat $file | grep -iv 'http[s]://[a-z.-]*/[a-z0-9+-/]*[.jpg]' | jq -sRr @uri)"
    CAPTION="$(cat $file | grep -iv 'http[s]://[a-z.-]*/[a-z0-9+-/]*[.jpg]' | jq -sRr @uri)"
    IMAGEURL=$(cat file | grep -Poi 'http[s]://[a-z0-9-.\/]*.(jpg)|(png)|(jpeg)(gif)$' )



# curl -X GET "https://graph.facebook.com/v12.0/17841408630115897/media?access_token=${TOKEN}" | jq .

# curl -X GET "https://graph.facebook.com/v12.0/${IGID}/media?access_token=${TOKEN}" | jq .

CREATIONID=$( curl -X POST "https://graph.facebook.com/${IGID}/media?image_url=${IMAGEURL}&caption=${CAPTION}&access_token=${TOKEN}" | jq -r .id )

if [ CREATIONID:- ] ; then
  curl -X POST "https://graph.facebook.com/${IGID}/media_publish?creation_id=${CREATIONID}&access_token=${TOKEN}" | jq .
else
  CREATIONID not created
fi
# POST graph.facebook.com/17841400008460056/media
#  ?image_url=https//www.example.com/images/bronz-fonz.jpg
#   &caption=%23BronzFonz


