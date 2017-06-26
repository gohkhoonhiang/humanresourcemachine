require_relative './command/command_regex'
require_relative './command/inbox'
require_relative './command/outbox'
require_relative './command/end_of_file'
require_relative './command/subtract'
require_relative './command/add'
require_relative './command/jump_z'
require_relative './command/jump_n'
require_relative './command/jump'
require_relative './command/bump_up'
require_relative './command/bump_down'
require_relative './command/copy_to'
require_relative './command/copy_from'
require_relative './command/label'

module HRM
  class CommandMatcher
    include ::HRM::Command::CommandRegex

    def self.match(cmd)
      case
      when cmd.match(INB) then Command::Inbox.new(cmd)
      when cmd.match(OUB) then Command::Outbox.new(cmd)
      when cmd.match(EOF) then Command::EndOfFile.new(cmd)
      when cmd.match(SUB) then Command::Subtract.new(cmd)
      when cmd.match(ADD) then Command::Add.new(cmd)
      when cmd.match(JPZ) then Command::JumpZ.new(cmd)
      when cmd.match(JPN) then Command::JumpN.new(cmd)
      when cmd.match(JMP) then Command::Jump.new(cmd)
      when cmd.match(BUP) then Command::BumpUp.new(cmd)
      when cmd.match(BDN) then Command::BumpDown.new(cmd)
      when cmd.match(CPT) then Command::CopyTo.new(cmd)
      when cmd.match(CPF) then Command::CopyFrom.new(cmd)
      when cmd.match(LBL) then Command::Label.new(cmd)
      end
    end

  end
end
