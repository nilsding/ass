require 'childprocess'
require 'tempfile'

class Runscript

  # Runtime status
  attr_reader :status
  # Hash containing the environment variables
  attr_reader :environment
  # The temp file
  attr_reader :tmp_file
  # Current path
  attr_accessor :cwd

  def initialize(&block)
    @environment = {}
    @pids = {}
    @callbacks = {}
    @status = :stopped
    @tmp_file = Tempfile.new('output')
    @processes = []
    @cwd = File.expand_path('../tmp', File.dirname(__FILE__))
    AVAILABLE_CALLBACKS.each { |k| @callbacks[k] = nil }
    instance_eval &block

    at_exit { cleanup }
  end

  # Sets an environment variable.
  # @param key [Symbol] The key of the environment variable
  # @param val [String] The value of the environment variable
  def setenv(key, val)
    @environment[key] = val
  end

  # Unsets an environment variable.
  # @param key [Symbol] The key of the environment variable
  def unset(key)
    @environment.delete key
  end

  # Executes a shell command.
  # @param cmd [String] The command line to be executed.
  # @param options [Hash] A customizable set of options.
  # @option options [Symbol] :pid This symbol is an alias of the PID of the executed process
  # @option options [Boolean] :wait (true) Wait until the process has exited
  def sh(cmd, options = {})
    opts = {
      pid: nil,
      wait: true
    }.merge!(options)

    cmd.strip!

    ChildProcess.posix_spawn = true
    process = ChildProcess.build 'bash', '--login', '-c', cmd

    @environment.each { |k, v| process.environment[k.to_s] = v }

    process.io.stdout = @tmp_file
    process.io.stderr = @tmp_file
    process.cwd = @cwd

    _puts "#{Time.now.to_s} | #{cmd}"

    process.start

    @processes << process
    @pids[opts[:pid]] = process.pid unless opts[:pid].nil?

    process.wait if opts[:wait]
  end

  # Sends a signal to a process.
  # @param process [Symbol] The PID of a process
  # @param options [Hash] A customizable set of options.
  # @option options [Symbol] :with (:SIGKILL) The signal to send
  def kill(process, options = {})
    opts = {
      with: :SIGKILL
    }.merge!(options)
    signal = opts[:with]
    pid = @pids[process]
    _puts "#{Time.now.to_s} | Killing #{process} (#{pid}) #{signal == :SIGKILL ? "forcefully" : "softly"} with signal #{signal}"
    Process.kill(signal, pid)
    @processes.delete pid
  end

  # Starts the runscript
  def run!
    return if %i(starting started).include? @status
    @status = :starting
    @callbacks[:before_start].call  unless @callbacks[:before_start].nil?
    @callbacks[:start].call         unless @callbacks[:start].nil?
    @status = :started
    @callbacks[:after_start].call   unless @callbacks[:after_start].nil?
  end

  # Stops the runscript
  def stop!
    return if %i(stopping stopped).include? @status
    @status = :stopping
    @callbacks[:before_stop].call   unless @callbacks[:before_stop].nil?
    @callbacks[:stop].call          unless @callbacks[:stop].nil?
    @status = :stopped
    @callbacks[:after_stop].call    unless @callbacks[:after_stop].nil?
    cleanup
  end

  # Restarts the runscript.
  def restart!
    case @status
      when :started
        stop!
        run!
      when :stopped
        run!
      else
        _puts "#{Time.now.to_s} | Tried to restart while starting or stopping!"
    end
  end

  def method_missing(name, *_args, &block)
    super unless AVAILABLE_CALLBACKS.include? name
    @callbacks[name] = block
  end

  def _puts(*args)
    puts *args
    @tmp_file.write "#{args * ' '}\n"
    @tmp_file.flush
  end

  private

  AVAILABLE_CALLBACKS = %i(
    before_start start after_start
    before_stop stop after_stop
  )

  def cleanup
    _puts "#{Time.now.to_s} | Cleanup..."
    @processes.each do |process|
      if process.exited?
        _puts "#{Time.now.to_s} | #{process.pid} exited with status #{process.exit_code}"
      else
        _puts "#{Time.now.to_s} | stopping #{process.pid} (timeout 5 seconds)..."
        begin
          Process.kill(:SIGINT, process.pid)
          process.poll_for_exit(5)
          _puts "#{Time.now.to_s} | #{process.pid} exited with status #{process.exit_code}"
        rescue ChildProcess::TimeoutError
          _puts "#{Time.now.to_s} | forcefully stopping #{process.pid}"
          process.stop
        end
      end
    end
    @processes = []
  end
end