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
