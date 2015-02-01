Runscript.new do

  before_start do
    sh %|echo "before_start"|
    sh %|pwd|
    sh %|ls -la|
    setenv :TEST, 'Test successful!'
  end

  start do
    sh %|echo "start"|
    sh %|sleep 5|, pid: :sleep, wait: true
    sh %|echo $TEST|
    sh %|sleep 10|, pid: :sleep2, wait: false
  end

  after_start do
    sh %|echo "after_start"|
  end

  before_stop do
    sh %|echo "before_stop"|
  end

  stop do
    sh %|echo 1 $TEST|
    unset :TEST
    sh %|echo 2 $TEST|
    kill :sleep2, with: :SIGINT
  end

  after_stop do
    sh %|echo "after_stop"|
  end
end