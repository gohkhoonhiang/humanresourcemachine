require_relative './command_regex'

module HRM
  module Command
    class Label
      include CommandRegex

      attr_reader :matcher

      def initialize(cmd)
        @cmd = cmd
        @matcher = cmd.match(LBL)
      end

      def execute(_machine_state)
      end

    end
  end
end
