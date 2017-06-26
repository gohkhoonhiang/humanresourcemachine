require_relative './command_regex'

module HRM
  module Command
    class EndOfFile
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(EOF)
      end

      def execute(machine_state)
        machine_state.finished = true
      end

    end
  end
end
