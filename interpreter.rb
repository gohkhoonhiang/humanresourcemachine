#!/usr/bin/ruby

require 'optparse'

class HRMInterpreter
  attr_accessor :verbose
  attr_reader :memspace, :mem, :constants, :commands, :inputs, :labels,
              :outputs

  def initialize(parser)
    @verbose = parser.verbose
    @memspace = 0
    @mem = []
    @constants = []
    @commands = []
    @inputs = []
    @labels = {}
    @outputs = []
    read_init(parser.init_filename)
    read_commands(parser.cmd_filename)
    read_inputs(parser.in_filename)
    init_vm
    init_labels
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

  def init_labels
    @commands.each_with_index do |cmd,index|
      m = cmd.match(/(?<label>\w+):/)
      if !m.nil?
        lbl = m['label']
        @labels[lbl] = index  
      end
    end
    print_log(format("labels: %s", labels))
    print_log("init labels done...")
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
    @commands.each { |cmd| cmd.strip! }
  end

  def read_inputs(file_name)
    print_log("read_inputs...")
    line = ""
    line = File.read(file_name)
    line.strip.split(" ").each { |val| @inputs.push(get_raw_val(val)) }
  end

  def add_raw(left, right)
    if left.instance_of?(String) && right.instance_of?(String)
      print_error(format("Unable to add values of non-integer types"))
      exit
    end
    left + right
  end

  def sub_raw(left, right)
    result = 0
    if left.class != right.class
      print_error(format("Unable to sub values of different types %s, %s",
                          left.class, right.class))
      exit
    elsif left.instance_of?(Fixnum) && right.instance_of?(Fixnum)
      result = left - right
    elsif left.instance_of?(String) && right.instance_of?(String)
      lm = left.match(/[^\d]+/)
      rm = right.match(/[^\d]+/)
      if lm.nil? and rm.nil?
        result = left.to_i - right.to_i
      elsif !lm.nil? and !rm.nil?
        result = left.ord - right.ord
      else
        print_error(format("Unable to sub values of different types %s, %s",
                            left.class, right.class))
        exit
      end
    end
    result
  end

  def cmp_raw(left, op, right)
    if left.instance_of?(String)
      lm = left.match(/[^\d]+/)
      left = lm.nil? ? left.to_i : left.ord
    end
    if right.instance_of?(String)
      rm = right.match(/[^\d]+/)
      right = rm.nil? ? right.to_i : right.ord
    end
    compare(left, op, right)
  end

  def compare(left, op, right)
    result =
      case op
      when "eq" then left == right
      when "ne" then left != right
      when "lt" then left < right
      when "gt" then left > right
      when "lte" then left <= right
      when "gte" then left >= right
      else
        print_error(format("Invalid operation %s", op))
        exit
      end
    result
  end

  def get_val_from_mem(i)
    i = i.to_i if i.instance_of?(String)
    @mem[i]
  end

  def set_val_to_mem(i, val)
    i = i.to_i if i.instance_of?(String)
    @mem[i] = val
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

  def print_error(line)
    puts format("Error: %s", line)
  end

  def print_warn(line)
    puts format("Warning: %s", line)
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
    print @labels
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
  interpreter = HRMInterpreter.new(parser)

  print interpreter.to_s
end 
