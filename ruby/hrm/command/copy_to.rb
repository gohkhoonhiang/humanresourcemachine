require_relative './command_regex'

module HRM
  module Command
    class CopyTo
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(CPT)
      end

      def execute(machine_state)
        if !matcher['addr'].nil?
          addr = matcher['addr']
          i = machine_state.get_val_from_mem(addr)
          machine_state.set_val_to_mem(i, machine_state.x)
        else
          i = matcher['index']
          machine_state.set_val_to_mem(i, machine_state.x)
        end
      end

    end
  end
end
