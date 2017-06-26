require_relative './logger'
require_relative './machine_state'
require_relative './operator'

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
      while !machine_state.finished && machine_state.ptr >= 0 && machine_state.ptr < machine_state.commands.length do
        logger.info(format("mem: %s", machine_state.mem))
        cmd = machine_state.commands[machine_state.ptr]
        logger.info(format("interpreting commands[%d]: %s", machine_state.ptr, cmd))
        if cmd.match(inb)
          if machine_state.inputs.empty?
            machine_state.finished = true
          else
            machine_state.x = machine_state.inputs.delete_at(0)
          end
        elsif cmd.match(oub)
          machine_state.outputs.push(machine_state.x)
          machine_state.x = nil
        elsif cmd.match(add)
          m = cmd.match(add)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.x = ::HRM::Operator.add_raw(machine_state.x, machine_state.get_val_from_mem(i))
          else
            i = m['index']
            machine_state.x = ::HRM::Operator.add_raw(machine_state.x, machine_state.get_val_from_mem(i))
          end
        elsif cmd.match(sub)
          m = cmd.match(sub)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.x = ::HRM::Operator.sub_raw(machine_state.x, machine_state.get_val_from_mem(i))
          else
            i = m['index']
            machine_state.x = ::HRM::Operator.sub_raw(machine_state.x, machine_state.get_val_from_mem(i))
          end
        elsif cmd.match(jpz)
          unless !::HRM::Operator.cmp_raw(machine_state.x, "eq", 0)
            m = cmd.match(jpz)
            label = m['label']
            machine_state.ptr = machine_state.labels[label]
          end
        elsif cmd.match(jpn)
          unless !::HRM::Operator.cmp_raw(machine_state.x, "lt", 0)
            m = cmd.match(jpn)
            label = m['label']
            machine_state.ptr = machine_state.labels[label]
          end
        elsif cmd.match(jmp)
          m = cmd.match(jmp)
          label = m['label']
          machine_state.ptr = machine_state.labels[label]
        elsif cmd.match(bup)
          m = cmd.match(bup)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.set_val_to_mem(i, ::HRM::Operator.add_raw(machine_state.get_val_from_mem(i), 1))
            machine_state.x = machine_state.get_val_from_mem(i)
          else
            i = m['index']
            machine_state.set_val_to_mem(i, ::HRM::Operator.add_raw(machine_state.get_val_from_mem(i), 1))
            machine_state.x = machine_state.get_val_from_mem(i)
          end
        elsif cmd.match(bdn)
          m = cmd.match(bdn)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.set_val_to_mem(i, ::HRM::Operator.sub_raw(machine_state.get_val_from_mem(i), 1))
            machine_state.x = machine_state.get_val_from_mem(i)
          else
            i = m['index']
            machine_state.set_val_to_mem(i, ::HRM::Operator.sub_raw(machine_state.get_val_from_mem(i), 1))
            machine_state.x = machine_state.get_val_from_mem(i)
          end
        elsif cmd.match(cpt)
          m = cmd.match(cpt)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.set_val_to_mem(i, machine_state.x)
          else
            i = m['index']
            machine_state.set_val_to_mem(i, machine_state.x)
          end
        elsif cmd.match(cpf)
          m = cmd.match(cpf)
          if !m['addr'].nil?
            addr = m['addr']
            i = machine_state.get_val_from_mem(addr)
            machine_state.x = machine_state.get_val_from_mem(i)
          else
            i = m['index']
            machine_state.x = machine_state.get_val_from_mem(i)
          end
        elsif cmd.match(eof)
          machine_state.finished = true
        elsif cmd.match(lbl)
          # label
        else
          logger.warn(format("Ignore command %s", cmd))
        end
        machine_state.ptr += 1
        steps += 1
        logger.info(format("ptr: %d", machine_state.ptr))
      end
      logger.info(format("interpreted in %d steps with %d commands",
                         steps, machine_state.commands.length))
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
