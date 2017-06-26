require_relative './command_regex'

module HRM
  module Command
    class Inbox
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(INB)
      end

      def execute(machine_state)
        if machine_state.inputs.empty?
          machine_state.finished = true
        else
          machine_state.x = machine_state.inputs.delete_at(0)
        end
      end

    end
  end
end
