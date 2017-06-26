require_relative './command_regex'
require_relative '../operator'

module HRM
  module Command
    class JumpZ
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(JPZ)
      end

      def execute(machine_state)
        unless !::HRM::Operator.cmp_raw(machine_state.x, "eq", 0)
          label = matcher['label']
          machine_state.ptr = machine_state.labels[label]
        end
      end

    end
  end
end
