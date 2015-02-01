#!/usr/bin/env ruby
require 'git'
require 'haml'
require 'yaml'
require 'sinatra'
require 'fileutils'
$LOAD_PATH.unshift File.expand_path './lib', File.dirname(__FILE__)
require 'runscript'

# Hash containing the configuration.
CONFIG = YAML.load_file File.expand_path('./config.yml', File.dirname(__FILE__))
# Version of ass
ASS_VERSION = '0.1.0'

cwd = File.expand_path('.', CONFIG[:repo_path])
FileUtils.mkdir_p(cwd)
$runscript = eval(File.read File.expand_path('.', CONFIG[:runscript]))
$runscript.cwd = cwd
unless Dir.exist? File.expand_path('.git', cwd)
  $runscript._puts "#{Time.now.to_s} | Cloning git repo to #{cwd}"
  Git.clone(CONFIG[:git_repo], cwd)
end

$git = Git.open cwd

def have_local_branch?(branch_name)
  $git.branches.local.each { |branch| return true if branch.name == branch_name }
  false
end

get '/' do
  haml :index
end

post '/git' do
  case params[:action]
  when "pull"
    $runscript.sh "git pull"
  when "fetch"
    $runscript.sh "git fetch"
  when "branch"
    $runscript._puts "#{Time.now.to_s} | Switching to branch #{params[:branch]}"
    if have_local_branch?(params[:branch])
      $runscript.sh "git checkout #{params[:branch]}"
    else
      $runscript.sh "git checkout -b #{params[:branch]} --force --track origin/#{params[:branch]}"
    end
    $runscript.sh "git pull"
  end
  redirect '/'
end

post '/start_stop_app' do
  case params[:action]
  when "start"
    $runscript.run!
  when "restart"
    $runscript.restart!
  when "stop"
    $runscript.stop!
  end
  redirect '/'
end