Morning Pages Journal
=====================

A command line tool to manage morning pages.

    Morning Pages are three pages of longhand, stream of consciousness writing,
    done first thing in the morning. *There is no wrong way to do Morning Pages*–
    they are not high art. They are not even “writing.” They are about
    anything and everything that crosses your mind– and they are for your eyes
    only. Morning Pages provoke, clarify, comfort, cajole, prioritize and
    synchronize the day at hand. Do not over-think Morning Pages: just put
    three pages of anything on the page…and then do three more pages tomorrow.

Usage
-----

### To open current day morning page in editor:

    $ mp

### To list morning pages and progress:
    
    $ mp list       # current month
    $ mp list -w    # current week
    $ mp list -d    # curent day
    $ mp list -m    # current month
    $ mp list -y    # current year

### To get stats:

    $ mp stat       # current month
    $ mp stat -w    # current week
    $ mp stat -d    # curent day
    $ mp stat -m    # current month
    $ mp stat -y    # current year
    
### To count words:

    $ mp words       # current month
    $ mp words -w    # current week
    $ mp words -d    # curent day
    $ mp words -m    # current month
    $ mp words -y    # current year

Configuration
-------------

A  `~/.mp.yml` file will be created that looks like

    editor: mate
    folder: ~/.morning-pages/
    words: 750
    stats: 50

You can change setting manually or use 

    mp config <key> <value>
    mp config editor vi 
    
You can also specify a config file and run any of the commands

    mp -c custom.yaml list
    

Installation
------------

    gem install morning-pages-journal
