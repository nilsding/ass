# This is a example runscript for starting a Rails application.

Runscript.new do

  before_start do
    # set Rails environment to development
    setenv :RAILS_ENV, 'development'

    # install bundle
    sh %|bundle install --without production|

    # migrate the database
    sh %|bundle exec rake db:migrate|
  end

  start do
    sh %|bundle exec rails server|, pid: :rails, wait: false
  end

  stop do
    unset :RAILS_ENV
    kill :rails, with: :SIGINT
  end
end