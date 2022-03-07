Publish-Instagram
#################

Usage

::

    Usage: $0 <OPTION>
    
    Options:
      -d                           dry run
      -f <file>                    just publish from postqueue
      -q                           show quota usage
      -h                           shows this help
    
    Requirements:
      credentials.txt
      imagemagick


**-d**
  dry-run.
  Just pretends it does something, but doesn't publish

**-f**
  Publishes from a list of images on a file
  This skips the processing of the webpage and pushes immediately the images of a preconfigured file.
  (useful for quick fixes)
  
  File format:

  ::
  
      <image url><space><caption html format>


  Example:

  .. code-block:: TEXT
  
      https://example.com/images/igpostyDuBp4Ye.JPEG Post%20by%3A%20User


**-q**
  Shows the current facebook allowance for postings

  ::
  
      $ sh publish-instagram.sh -q
      {
        "data": [
                  {
            "config": {
              "quota_total": 25,
              "quota_duration": 86400
            },
            "quota_usage": 7
          }
        ]
      }

Configuration
=============

You need a file called ``credentials.txt`` and it should look like this:

.. code-block:: SHELL

    TOKEN="THisIsMyFACEBOOKappTokenTHAThappensTObeVERYlong"
    IGID=99999999999999999
    appid="8888888888888888"
    appsecret="1234567890abcdef1234567890abcdef"
    apiversion="v12.0"
    userid="77777777777777777"


Execution
=========

Add the following to your crontab to execute this every 30 minutes

.. code-block:: TEXT

    */30   *    *   *   *   ( cd /srv/publish-instagram ; sh publish-instagram.sh )


Publishing new images to instagram
==================================

Extract Posts from html
-----------------------


1. get the credentials from ``credentials.txt`` file
2. create HASHTAGSBLOCK string
3. Get the latest Topic from the forum board, and convert it from HTML to restructuredtext.
4. Get the latest post from the file
5. if the latest post matches the local latest post (``lastpost.txt``), **carry on**
    5.1. identify the line with the last post (*deprecated - not doing that anymore*)


- Split "^Post" and create new files. Process until find "``\`SMF``"
- Delete the last line on each snippet.

.. code-block:: SHELL

    awk '/^Post/{ f = sprintf("docs/doc_%04d.text", d++) } f{print > f} /^SMF/{f=""}' "bcimages${TOPIC}.text"
    sed -i '$d' docs/doc*


Process images on files
-----------------------

For every mention of image like ``jpg`` ``jpeg`` or ``png`` inside **docs**

1. grab the caption

2. with imagemagick, grab *width*, *height*, *format* and *checksum*

.. code-block:: SHELL

    identify -format "%w %h %m %#" $file


3. If the checksum found is not on the list

- check the proportions of the image

  - make it square if portrait
  - if landscape and too wide, make it 16:9

- add image location and caption to the ``postqueue.txt``

- add the new found checksum to the list of known images ``bcimages${TOPIC}.hash``

4. Publish the contents of ``postqueue.txt``. On each entry of
   ``postqueue.txt``, posts the picture on instagram with the caption and the
   HASHTAGSBLOCK.

5. Clean up. Deletes all the temporary files created.