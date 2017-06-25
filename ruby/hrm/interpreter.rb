module HRM
  class Interpreter
    attr_reader :verbose, :memspace, :mem, :constants, :commands, :inputs,
                :labels, :outputs

    def initialize(init_filename, cmd_filename, in_filename, verbose = true)
      @verbose = verbose
      @memspace = 0
      @mem = []
      @constants = []
      @commands = []
      @inputs = []
      @labels = {}
      @outputs = []
      read_init(init_filename)
      read_commands(cmd_filename)
      read_inputs(in_filename)
      init_vm
      init_labels
    end

    def init_vm
      print_log("init vm...")
      print_log(format("memspace: %d", @memspace))
      @mem = Array.new(@memspace)
      index = @memspace - 1
      @constants.each do |const|
        @mem[index] = const
        index = index - 1
      end
      print_log(format("mem: %s", @mem))
      print_log("init done...")
    end

    def init_labels
      @commands.each_with_index do |cmd, index|
        m = cmd.match(/(?<label>\w+):/)
        next if m.nil?
        lbl = m['label']
        @labels[lbl] = index
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
      if left.is_a?(String) && right.is_a?(String)
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
      elsif left.is_a?(Fixnum) && right.is_a?(Fixnum)
        result = left - right
      elsif left.is_a?(String) && right.is_a?(String)
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
      if left.is_a?(String)
        lm = left.match(/[^\d]+/)
        left = lm.nil? ? left.to_i : left.ord
      end
      if right.is_a?(String)
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
      i = i.to_i if i.is_a?(String)
      @mem[i]
    end

    def set_val_to_mem(i, val)
      i = i.to_i if i.is_a?(String)
      @mem[i] = val
    end

    def get_raw_val(val)
      return if val.nil?
      val.match(/\d+/).nil? ? val : val.to_i
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
      output = <<-OUTPUT
      mem: #{mem}
      memspace: #{memspace}
      constants: #{constants}
      inputs: #{inputs}
      commands: #{commands}
      labels: #{labels}
      outputs: #{outputs}
      OUTPUT
      puts output
    end
  end
end
