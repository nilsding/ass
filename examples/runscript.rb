#!/usr/bin/env ruby
# This is an example for starting a runscript.

$LOAD_PATH.unshift File.expand_path '../lib', File.dirname(__FILE__)
require 'runscript'

runscript = eval(File.read './scripts/simple-test.rb')

runscript.run!

puts "Doing something... (waiting 5 seconds)"
sleep 5

runscript.stop!