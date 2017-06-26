require 'optparse'

module HRM
  class OptionParser
    attr_accessor :init_filename, :cmd_filename, :in_filename, :verbose

    def initialize
      @init_filename = nil
      @cmd_filename = nil
      @in_filename = nil
      @verbose = false
    end

    def parse!
      parser = ::OptionParser.new do |opts|
        opts.banner = "Usage: hrm_cli.rb [options]"

        opts.on('-n', '--init init_filename', 'Init filename') do |init_filename|
          @init_filename = init_filename
        end

        opts.on('-c', '--cmd cmd_filename', 'Commands filename') do |cmd_filename|
          @cmd_filename = cmd_filename
        end

        opts.on('-i', '--in in_filename', 'Inputs filename') do |in_filename|
          @in_filename = in_filename
        end

        opts.on('-v', '--verbose', 'Verbose') do
          @verbose = true
        end

        opts.on('-h', '--help', 'Help') do
          puts opts
          exit
        end
      end

      parser.parse!

      check_required

      check_file
    end

    def check_required
      required = []
      if @init_filename.nil?
        required.push("--init")
      end
      if @cmd_filename.nil?
        required.push("--cmd")
      end
      if @in_filename.nil?
        required.push("--in")
      end
      if !required.empty?
        puts "error: the following arguments are required: #{required.join(', ')}"
        exit
      end
    end

    def check_file
      [@init_filename, @cmd_filename, @in_filename].each do |filename|
        if !File.exist?(filename)
          puts format("%s not found", filename)
          exit
        end
      end
    end
  end
end
