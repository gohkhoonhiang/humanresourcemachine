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

  def interpret
    steps = 0
    print_log("interpreting...")
    inb = Regexp.new(/INBOX/)
    oub = Regexp.new(/OUTBOX/)
    eof = Regexp.new(/END/)
    sub = Regexp.new(/SUB\s+\[(?<addr>\d+)\]|SUB\s+(?<index>\d+)/)
    add = Regexp.new(/ADD\s+\[(?<addr>\d+)\]|ADD\s+(?<index>\d+)/)
    jpz = Regexp.new(/JUMPZ\s+(?<label>\w+)/)
    jpn = Regexp.new(/JUMPN\s+(?<label>\w+)/)
    jmp = Regexp.new(/JUMP\s+(?<label>\w+)/)
    bup = Regexp.new(/BUMPUP\s+\[(?<addr>\d+)\]|BUMPUP\s+(?<index>\d+)/)
    bdn = Regexp.new(/BUMPDN\s+\[(?<addr>\d+)\]|BUMPDN\s+(?<index>\d+)/)
    cpt = Regexp.new(/COPYTO\s+\[(?<addr>\d+)\]|COPYTO\s+(?<index>\d+)/)
    cpf = Regexp.new(/COPYFROM\s+\[(?<addr>\d+)\]|COPYFROM\s+(?<index>\d+)/)
    lbl = Regexp.new(/(?<label>\w+):/)
    ptr = 0
    x = nil
    finished = false
    while !finished && ptr >= 0 && ptr < commands.length do
      print_log(format("mem: %s", @mem))
      cmd = @commands[ptr]
      print_log(format("interpreting commands[%d]: %s", ptr, cmd))
      if cmd.match(inb)
        if @inputs.empty?
          finished = true
        else
          x = inputs.delete_at(0)
        end
      elsif cmd.match(oub)
        @outputs.push(x)
        x = nil
      elsif cmd.match(add)
        m = cmd.match(add)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          x = add_raw(x, get_val_from_mem(i))
        else
          i = m['index']
          x = add_raw(x, get_val_from_mem(i))
        end
      elsif cmd.match(sub)
        m = cmd.match(sub)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          x = sub_raw(x, get_val_from_mem(i))
        else
          i = m['index']
          x = sub_raw(x, get_val_from_mem(i))
        end
      elsif cmd.match(jpz)
        unless !cmp_raw(x, "eq", 0)
          m = cmd.match(jpz)
          label = m['label']
          ptr = @labels[label]
        end
      elsif cmd.match(jpn)
        unless !cmp_raw(x, "lt", 0)
          m = cmd.match(jpn)
          label = m['label']
          ptr = @labels[label]
        end
      elsif cmd.match(jmp)
        m = cmd.match(jmp)
        label = m['label']
        ptr = @labels[label]
      elsif cmd.match(bup)
        m = cmd.match(bup)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          set_val_to_mem(i, add_raw(get_val_from_mem(i), 1))
          x = get_val_from_mem(i)
        else
          i = m['index']
          set_val_to_mem(i, add_raw(get_val_from_mem(i), 1))
          x = get_val_from_mem(i)
        end
      elsif cmd.match(bdn)
        m = cmd.match(bdn)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          set_val_to_mem(i, sub_raw(get_val_from_mem(i), 1))
          x = get_val_from_mem(i)
        else
          i = m['index']
          set_val_to_mem(i, sub_raw(get_val_from_mem(i), 1))
          x = get_val_from_mem(i)
        end
      elsif cmd.match(cpt)
        m = cmd.match(cpt)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          set_val_to_mem(i, x)
        else
          i = m['index']
          set_val_to_mem(i, x)
        end
      elsif cmd.match(cpf)
        m = cmd.match(cpf)
        if !m['addr'].nil?
          addr = m['addr']
          i = get_val_from_mem(addr)
          x = get_val_from_mem(i)
        else
          i = m['index']
          x = get_val_from_mem(i)
        end
      elsif cmd.match(eof)
        finished = true
      elsif cmd.match(lbl)
        # label
      else
        print_warn(format("Ignore command %s", cmd))
      end
      ptr += 1
      steps += 1
      print_log(format("ptr: %d", ptr))
    end
    print_log(format("interpreted in %d steps with %d commands",
                      steps, @commands.length))
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
    print "mem: ", @mem
    puts
    print "memspace: ", @memspace
    puts
    print "constants: ", @constants
    puts
    print "inputs: ", @inputs
    puts
    print "commands: ", @commands
    puts
    print "labels: ", @labels
    puts
    print "outputs: ", @outputs
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

  puts "Before:"
  print interpreter.to_s

  interpreter.interpret

  puts "After:"
  print interpreter.to_s
end 
