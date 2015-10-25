require 'logger'

module Travis
  class Logger < ::Logger # TODO
    require 'travis/logger/format'

    class << self
      def new(io, config = {})
        configure(config, super(io))
      end

      def configure(config, logger)
        logger.formatter = Format.new(config[:logger])
        logger.level = level_for(config)
        logger
      end

      def level_for(config)
        level = config.fetch(:logger, {})[:level] || config[:log_level] || :debug
        Logger.const_get(level.to_s.upcase)
      end
    end

    [:fatal, :error, :warn, :info, :debug].each do |level|
      define_method(level) do |msg, options = {}|
        if msg.is_a?(Exception)
          exception = msg
          msg = "#{exception.class.name}: #{exception.message}"
          msg << "\n#{exception.backtrace.join("\n")}" if exception.backtrace
        end

        msg = msg.join("\n") if msg.respond_to?(:join)
        msg = msg.chomp + "\n"

        super(msg)
      end
    end
  end
end
