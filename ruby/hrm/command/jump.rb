require_relative './command_regex'

module HRM
  module Command
    class Jump
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(JMP)
      end

      def execute(machine_state)
        label = matcher['label']
        machine_state.ptr = machine_state.labels[label]
      end

    end
  end
end
