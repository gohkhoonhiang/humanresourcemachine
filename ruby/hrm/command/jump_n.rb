require_relative './command_regex'
require_relative '../operator'

module HRM
  module Command
    class JumpN
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(JPN)
      end

      def execute(machine_state)
        unless !::HRM::Operator.cmp_raw(machine_state.x, "lt", 0)
          label = matcher['label']
          machine_state.ptr = machine_state.labels[label]
        end
      end

    end
  end
end
