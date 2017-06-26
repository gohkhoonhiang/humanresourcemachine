require_relative './logger'
require_relative './machine_state'
require_relative './operator'
require_relative './command_matcher'

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
      while !machine_state.terminate? do
        logger.info(format("mem: %s", machine_state.mem))
        cmd = machine_state.next_command

        machine_command = ::HRM::CommandMatcher.match(cmd)
        if machine_command
          machine_command.execute(machine_state)
        else
          logger.error(format("Ignore command %s", cmd))
        end

        logger.info(format("interpreting commands[%d]: %s", machine_state.ptr, cmd))
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
