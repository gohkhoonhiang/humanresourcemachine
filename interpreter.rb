#!/usr/bin/ruby

require 'optparse'

class HRMInterpreter
  attr_accessor :verbose

  def initialize
    self.verbose = false
  end

  def init_vm(memspace, consts)
    print_log("init vm...")
    print_log(format("memspace: %d", memspace))
    mem = [nil] * memspace
    index = memspace - 1
    consts.each do |const| 
      mem[index] = const
      index = index - 1
    end
    print_log(format("mem: %s", mem))
    print_log("init done...")
    mem
  end

  def read_init(file_name)
    print_log("read_init...")
    lines = []
    memspace = nil
    constants = []
    lines = File.readlines(file_name)
    memspace = lines.first.strip.to_i
    memspace = get_raw_val(lines.first.strip)
    if lines.length == 2
      lines[1].strip.split(" ").each { |val| constants.push(get_raw_val(val)) }
    end
    [memspace, constants]
  end

  def read_commands(file_name)
    print_log("read_commands...")
    commands = []
    commands = File.readlines(file_name)
    commands.each { |cmd| cmd.sub!("\t", " ") }
    commands
  end

  def read_inputs(file_name)
    print_log("read_inputs...")
    line = ""
    line = File.read(file_name)
    inputs = []
    line.strip.split(" ").each { |val| inputs.push(get_raw_val(val)) }
    inputs
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
end

def check_required(options)
  required = []
  if options[:init_filename].nil?
    required.push("--init")
  end
  if options[:cmd_filename].nil?
    required.push("--cmd")
  end
  if options[:in_filename].nil?
    required.push("--in")
  end
  if !required.empty?
    puts "error: the following arguments are required: #{required.join(', ')}"
    exit
  end
end

def check_file(filename)
  if !File.exist?(filename)
    puts format("%s not found", filename)
    exit
  end
end

if __FILE__ == $0
  options = {
    :init_filename => nil, :cmd_filename => nil, :in_filename => nil,
    :verbose => false
  }

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: interpreter.rb [options]"

    opts.on('-n', '--init init_filename', 'Init filename') do |init_filename|
      options[:init_filename] = init_filename
    end

    opts.on('-c', '--cmd cmd_filename', 'Commands filename') do |cmd_filename|
      options[:cmd_filename] = cmd_filename
    end

    opts.on('-i', '--in in_filename', 'Inputs filename') do |in_filename|
      options[:in_filename] = in_filename
    end

    opts.on('-v', '--verbose', 'Verbose') do
      options[:verbose] = true
    end

    opts.on('-h', '--help', 'Help') do
      puts opts
      exit
    end
  end

  parser.parse!

  check_required(options)

  check_file(options[:init_filename])
  check_file(options[:cmd_filename])
  check_file(options[:in_filename])
  verbose = options[:verbose]

  interpreter = HRMInterpreter.new
  interpreter.verbose = verbose

  memspace, constants = interpreter.read_init(options[:init_filename])
  commands = interpreter.read_commands(options[:cmd_filename])
  inputs = interpreter.read_inputs(options[:in_filename])
end 
