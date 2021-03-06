require_relative './command_regex'
require_relative '../operator'

module HRM
  module Command
    class BumpDown
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(BDN)
      end

      def execute(machine_state)
        if !matcher['addr'].nil?
          addr = matcher['addr']
          i = machine_state.get_val_from_mem(addr)
          machine_state.set_val_to_mem(i, ::HRM::Operator.sub_raw(machine_state.get_val_from_mem(i), 1))
          machine_state.x = machine_state.get_val_from_mem(i)
        else
          i = matcher['index']
          machine_state.set_val_to_mem(i, ::HRM::Operator.sub_raw(machine_state.get_val_from_mem(i), 1))
          machine_state.x = machine_state.get_val_from_mem(i)
        end
      end

    end
  end
end
