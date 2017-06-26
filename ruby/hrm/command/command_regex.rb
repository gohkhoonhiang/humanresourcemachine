module HRM
  module Command
    module CommandRegex

      INB ||= Regexp.new(/INBOX/)
      OUB ||= Regexp.new(/OUTBOX/)
      EOF ||= Regexp.new(/END/)
      SUB ||= Regexp.new(/SUB\s+\[(?<addr>\d+)\]|SUB\s+(?<index>\d+)/)
      ADD ||= Regexp.new(/ADD\s+\[(?<addr>\d+)\]|ADD\s+(?<index>\d+)/)
      JPZ ||= Regexp.new(/JUMPZ\s+(?<label>\w+)/)
      JPN ||= Regexp.new(/JUMPN\s+(?<label>\w+)/)
      JMP ||= Regexp.new(/JUMP\s+(?<label>\w+)/)
      BUP ||= Regexp.new(/BUMPUP\s+\[(?<addr>\d+)\]|BUMPUP\s+(?<index>\d+)/)
      BDN ||= Regexp.new(/BUMPDN\s+\[(?<addr>\d+)\]|BUMPDN\s+(?<index>\d+)/)
      CPT ||= Regexp.new(/COPYTO\s+\[(?<addr>\d+)\]|COPYTO\s+(?<index>\d+)/)
      CPF ||= Regexp.new(/COPYFROM\s+\[(?<addr>\d+)\]|COPYFROM\s+(?<index>\d+)/)
      LBL ||= Regexp.new(/(?<label>\w+):/)

    end
  end
end
