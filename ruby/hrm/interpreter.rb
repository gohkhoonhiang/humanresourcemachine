require_relative './logger'
require_relative './machine_state'

module HRM
  class Interpreter

    attr_reader :machine_state, :logger

    def initialize(init_filename, cmd_filename, in_filename, verbose = true)
      @verbose = verbose
      @logger = ::HRM::Logger.new(verbose)
      @machine_state = ::HRM::MachineState.new(logger)
      @machine_state.configure(init_filename, cmd_filename, in_filename)
    end

    def interpret
      steps = 0
      logger.info("interpreting...")
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
      while !finished && ptr >= 0 && ptr < machine_state.commands.length do
        logger.info(format("mem: %s", machine_state.mem))
        cmd = machine_state.commands[ptr]
        logger.info(format("interpreting commands[%d]: %s", ptr, cmd))
        if cmd.match(inb)
          if machine_state.inputs.empty?
            finished = true
          else
            x = machine_state.inputs.delete_at(0)
          end
        elsif cmd.match(oub)
          machine_state.outputs.push(x)
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
            ptr = machine_state.labels[label]
          end
        elsif cmd.match(jpn)
          unless !cmp_raw(x, "lt", 0)
            m = cmd.match(jpn)
            label = m['label']
            ptr = machine_state.labels[label]
          end
        elsif cmd.match(jmp)
          m = cmd.match(jmp)
          label = m['label']
          ptr = machine_state.labels[label]
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
          logger.warn(format("Ignore command %s", cmd))
        end
        ptr += 1
        steps += 1
        logger.info(format("ptr: %d", ptr))
      end
      logger.info(format("interpreted in %d steps with %d commands",
                         steps, machine_state.commands.length))
    end

    def add_raw(left, right)
      if left.is_a?(String) && right.is_a?(String)
        logger.error(format("Unable to add values of non-integer types"))
        exit
      end
      left + right
    end

    def sub_raw(left, right)
      result = 0
      if left.class != right.class
        logger.error(format("Unable to sub values of different types %s, %s",
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
          logger.error(format("Unable to sub values of different types %s, %s",
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
          logger.error(format("Invalid operation %s", op))
          exit
        end
      result
    end

    def get_val_from_mem(i)
      i = i.to_i if i.is_a?(String)
      machine_state.mem[i]
    end

    def set_val_to_mem(i, val)
      i = i.to_i if i.is_a?(String)
      machine_state.mem[i] = val
    end

    def to_s
      output = <<-OUTPUT
      mem: #{machine_state.mem}
      memspace: #{machine_state.memspace}
      constants: #{machine_state.constants}
      inputs: #{machine_state.inputs}
      commands: #{machine_state.commands}
      labels: #{machine_state.labels}
      outputs: #{machine_state.outputs}
      OUTPUT
      puts output
    end
  end
end
