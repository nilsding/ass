# Application Starting Service™

## WTF is ASS?

ASS is the Application Starting Service.  It provides a web interface to
(re)start and stop an application whenever you want.  It also has (basic)
support for Git repositories, so you can pull from remote and switch between
branches easily.

We're using it to start and stop the Retrospring development session. 

## Installation

### Production

    $ bundle install --without development
    $ cp config.yml.example config.yml
    $ vi config.yml
    $ ./app.rb -e production -p PORT

#### Example nginx config

``` nginx
server {
  listen 80;
  # change ass.local to your FQDN
  server_name ass.local;
  location / {
    proxy_set_header  X-Real-IP  $remote_addr;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_max_temp_file_size 0;

    proxy_pass http://127.0.0.1:PORT;
    break;
  }
}

```

### Development

    $ bundle install
    $ cp config.yml.example config.yml
    $ vi config.yml
    $ ./app.rb

## License

MIT