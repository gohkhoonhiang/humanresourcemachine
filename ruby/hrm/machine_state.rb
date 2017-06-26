module HRM
  class MachineState

    attr_reader :memspace, :mem, :constants, :commands, :inputs,
                :labels, :outputs, :logger

    def initialize(logger)
      @memspace = 0
      @mem = []
      @constants = []
      @commands = []
      @inputs = []
      @labels = {}
      @outputs = []
      @logger = logger
    end

    def configure(init_filename, cmd_filename, in_filename)
      read_init(init_filename)
      read_commands(cmd_filename)
      read_inputs(in_filename)
      init_vm
      init_labels
    end

    def read_init(file_name)
      logger.info("read_init...")
      lines = []
      lines = File.readlines(file_name)
      @memspace = lines.first.strip.to_i
      @memspace = get_raw_val(lines.first.strip)
      if lines.length == 2
        lines[1].strip.split(" ").each { |val| @constants.push(get_raw_val(val)) }
      end
    end

    def read_commands(file_name)
      logger.info("read_commands...")
      @commands = File.readlines(file_name)
      @commands.each { |cmd| cmd.strip! }
    end

    def read_inputs(file_name)
      logger.info("read_inputs...")
      line = ""
      line = File.read(file_name)
      line.strip.split(" ").each { |val| @inputs.push(get_raw_val(val)) }
    end

    def init_vm
      logger.info("init vm...")
      logger.info(format("memspace: %d", @memspace))
      @mem = Array.new(@memspace)
      index = @memspace - 1
      @constants.each do |const|
        @mem[index] = const
        index = index - 1
      end
      logger.info(format("mem: %s", @mem))
      logger.info("init done...")
    end

    def init_labels
      @commands.each_with_index do |cmd, index|
        m = cmd.match(/(?<label>\w+):/)
        next if m.nil?
        lbl = m['label']
        @labels[lbl] = index
      end
      logger.info(format("labels: %s", labels))
      logger.info("init labels done...")
    end

    def get_raw_val(val)
      return if val.nil?
      val.match(/\d+/).nil? ? val : val.to_i
    end

    def get_val_from_mem(i)
      i = i.to_i if i.is_a?(String)
      @mem[i]
    end

    def set_val_to_mem(i, val)
      i = i.to_i if i.is_a?(String)
      @mem[i] = val
    end

  end
end
