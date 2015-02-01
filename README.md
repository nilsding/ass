Application starting service™
=============================

Installation
------------

Production:

    $ bundle install --without development
    $ cp config.yml.example config.yml
    $ vi config.yml
    $ ./app.rb -e production

Development:

    $ bundle install
    $ cp config.yml.example config.yml
    $ vi config.yml
    $ ./app.rb

License
-------

MIT