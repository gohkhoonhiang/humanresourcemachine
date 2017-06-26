require_relative './command_regex'

module HRM
  module Command
    class Outbox
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(OUB)
      end

      def execute(machine_state)
        machine_state.outputs.push(machine_state.x)
        machine_state.x = nil
      end

    end
  end
end
