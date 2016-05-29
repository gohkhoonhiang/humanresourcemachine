#!/usr/bin/ruby

require 'optparse'

class HRMInterpreter
  attr_accessor :verbose
  attr_reader :memspace, :mem, :constants, :commands, :inputs

  def initialize
    @verbose = false
    @memspace = 0
    @mem = []
    @constants = []
    @commands = []
    @inputs = []
  end

  def init_vm
    print_log("init vm...")
    print_log(format("memspace: %d", @memspace))
    @mem = [nil] * @memspace
    index = @memspace - 1
    @constants.each do |const| 
      @mem[index] = const
      index = index - 1
    end
    print_log(format("mem: %s", @mem))
    print_log("init done...")
  end

  def read_init(file_name)
    print_log("read_init...")
    lines = []
    lines = File.readlines(file_name)
    @memspace = lines.first.strip.to_i
    @memspace = get_raw_val(lines.first.strip)
    if lines.length == 2
      lines[1].strip.split(" ").each { |val| @constants.push(get_raw_val(val)) }
    end
  end

  def read_commands(file_name)
    print_log("read_commands...")
    @commands = File.readlines(file_name)
    @commands.each { |cmd| cmd.sub!("\t", " ") }
  end

  def read_inputs(file_name)
    print_log("read_inputs...")
    line = ""
    line = File.read(file_name)
    line.strip.split(" ").each { |val| @inputs.push(get_raw_val(val)) }
  end

  def get_raw_val(val)
    raw_val = if !val.nil?
                !val.match(/\d+/).nil? ? val.to_i : val
              else
                nil
              end
    raw_val
  end

  def print_log(line)
    puts line if verbose
  end

  def to_s
    print @mem
    puts
    print @memspace
    puts
    print @constants
    puts
    print @inputs
    puts
    print @commands
    puts
  end
end

class HRMOptionParser
  attr_accessor :init_filename, :cmd_filename, :in_filename, :verbose

  def initialize
    @init_filename = nil
    @cmd_filename = nil
    @in_filename = nil
    @verbose = false
  end

  def parse!
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: interpreter.rb [options]"

      opts.on('-n', '--init init_filename', 'Init filename') do |init_filename|
        @init_filename = init_filename
      end

      opts.on('-c', '--cmd cmd_filename', 'Commands filename') do |cmd_filename|
        @cmd_filename = cmd_filename
      end

      opts.on('-i', '--in in_filename', 'Inputs filename') do |in_filename|
        @in_filename = in_filename
      end

      opts.on('-v', '--verbose', 'Verbose') do
        @verbose = true
      end

      opts.on('-h', '--help', 'Help') do
        puts opts
        exit
      end
    end

    parser.parse!

    check_required

    check_file
  end

  def check_required
    required = []
    if @init_filename.nil?
      required.push("--init")
    end
    if @cmd_filename.nil?
      required.push("--cmd")
    end
    if @in_filename.nil?
      required.push("--in")
    end
    if !required.empty?
      puts "error: the following arguments are required: #{required.join(', ')}"
      exit
    end
  end

  def check_file
    [@init_filename, @cmd_filename, @in_filename].each do |filename|
      if !File.exist?(filename)
        puts format("%s not found", filename)
        exit
      end
    end
  end
end

if __FILE__ == $0
  parser = HRMOptionParser.new
  parser.parse!
  interpreter = HRMInterpreter.new
  interpreter.verbose = parser.verbose

  interpreter.read_init(parser.init_filename)
  interpreter.read_commands(parser.cmd_filename)
  interpreter.read_inputs(parser.in_filename)
  interpreter.init_vm

  print interpreter.to_s
end 
