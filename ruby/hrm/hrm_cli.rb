#!/usr/bin/ruby

require_relative './option_parser'
require_relative './interpreter'

if __FILE__ == $0
  parser = HRM::OptionParser.new
  parser.parse!
  interpreter = HRM::Interpreter.new(parser.init_filename, parser.cmd_filename, parser.in_filename, parser.verbose)

  puts "Before:"
  print interpreter.to_s

  interpreter.interpret

  puts "After:"
  print interpreter.to_s
end
