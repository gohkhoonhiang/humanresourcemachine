require 'date'

module HRM
  class Logger

    attr_reader :verbose

    def initialize(verbose = true)
      @verbose = verbose
    end

    def info(message)
      puts "[HRM][#{DateTime.now}][INFO] #{message}" if verbose
    end

    def warn(message)
      puts "[HRM][#{DateTime.now}][WARN] #{message}" if verbose
    end

    def error(message)
      puts "[HRM][#{DateTime.now}][ERROR] #{message}" if verbose
    end

  end
end
