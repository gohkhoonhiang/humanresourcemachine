require_relative './logger'

module HRM
  module Operator
    extend self

    def logger
      @logger ||= ::HRM::Logger.new(true)
    end

    def add_raw(left, right)
      if left.is_a?(String) && right.is_a?(String)
        logger.error(format("Unable to add values of non-integer types"))
        exit
      end
      left + right
    end

    def sub_raw(left, right)
      result = 0
      if left.class != right.class
        logger.error(format("Unable to sub values of different types %s, %s",
                            left.class, right.class))
        exit
      elsif left.is_a?(Fixnum) && right.is_a?(Fixnum)
        result = left - right
      elsif left.is_a?(String) && right.is_a?(String)
        lm = left.match(/[^\d]+/)
        rm = right.match(/[^\d]+/)
        if lm.nil? and rm.nil?
          result = left.to_i - right.to_i
        elsif !lm.nil? and !rm.nil?
          result = left.ord - right.ord
        else
          logger.error(format("Unable to sub values of different types %s, %s",
                              left.class, right.class))
          exit
        end
      end
      result
    end

    def cmp_raw(left, op, right)
      if left.is_a?(String)
        lm = left.match(/[^\d]+/)
        left = lm.nil? ? left.to_i : left.ord
      end
      if right.is_a?(String)
        rm = right.match(/[^\d]+/)
        right = rm.nil? ? right.to_i : right.ord
      end
      compare(left, op, right)
    end

    def compare(left, op, right)
      result =
        case op
        when "eq" then left == right
        when "ne" then left != right
        when "lt" then left < right
        when "gt" then left > right
        when "lte" then left <= right
        when "gte" then left >= right
        else
          logger.error(format("Invalid operation %s", op))
          exit
        end
      result
    end

  end
end
