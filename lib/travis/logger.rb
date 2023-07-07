# frozen_string_literal: true

require 'logger'

module Travis
  class Logger < ::Logger
    require 'travis/logger/format'

    class << self
      def new(io, config = {})
        configure(super(io), config)
      end

      def configure(logger, config)
        logger.formatter = Format.new(config[:logger])
        logger.level = level_for(config)
        logger
      end

      def level_for(config)
        level = config.fetch(:logger, {})[:level] || config[:log_level] || :debug
        Logger.const_get(level.to_s.upcase)
      end
    end

    %i[fatal error warn info debug].each do |level|
      define_method(level) do |msg, options = {}|
        msg = msg.dup
        options.dup.tap do |opts|
          opts.delete(:progname)

          class << msg
            attr_reader :l2met_args
          end

          msg.instance_variable_set(:@l2met_args, opts)
        end

        super(msg)
      end
    end
  end
end
