require_relative './interpreter'

module HRM
  class App
    def self.interprete(init_filename, cmd_filename, in_filename)
      interpreter = ::HRM::Interpreter.new(init_filename, cmd_filename, in_filename)

      puts "Before:"
      print interpreter.to_s

      interpreter.interpret

      puts "After:"
      print interpreter.to_s
    end
  end
end
