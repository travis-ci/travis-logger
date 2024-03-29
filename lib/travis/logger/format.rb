# frozen_string_literal: false

require 'time'

module Travis
  class Logger
    class Format
      def initialize(config = {})
        @config = config || {}
      end

      def call(severity, time, progname, message)
        l2met_args = message.respond_to?(:l2met_args) ? message.l2met_args : {}

        send(
          "format_#{config[:format_type] || 'traditional'}",
          severity, time, progname, message_to_string(message), l2met_args
        )
      end

      def message_to_string(message)
        message = message.join("\n") if message.respond_to?(:join)

        message = case message
                  when Exception
                    exception = message
                    "#{exception.class.name}: #{exception.message}".tap do |s|
                      s << "\n#{exception.backtrace.join("\n")}" if exception.backtrace
                    end
                  when Hash
                    message.map do |k, v|
                      "#{k}=#{v}"
                    end.join(' ')
                  when String
                    message.chomp
                  else
                    message.inspect
                  end

        "#{message}\n"
      end

      private

      attr_reader :config

      def format_traditional(severity, time, progname, message, _l2met_args)
        traditional_format % log_record_vars(severity, time, progname, message)
      end

      def format_l2met(severity, time, progname, message, message_l2met_args)
        vars = log_record_vars(severity, time, progname, message)

        l2met_args = {
          time: vars[:formatted_time],
          level: vars[:severity_downcase].to_sym,
          msg: vars[:message].strip
        }

        l2met_args[:tid] = vars[:thread_id] if config[:thread_id]
        l2met_args[:pid] = vars[:process_id] if config[:process_id]
        l2met_args[:app] = vars[:process_name] if ENV['TRAVIS_PROCESS_NAME']

        l2met_args.merge!(message_l2met_args)

        "#{l2met_args_to_record(l2met_args).strip}\n"
      end

      def log_record_vars(severity, time, progname, message)
        {
          message: message.to_s,
          process_id: Process.pid,
          process_name: ENV['TRAVIS_PROCESS_NAME'],
          progname:,
          severity:,
          severity_downcase: severity.downcase,
          severity_initial: severity[0, 1],
          thread_id: Thread.current.object_id,
          time:
        }.tap do |v|
          if time_format
            v[:formatted_time] = time.strftime(time_format)
          elsif config[:format_type] == 'l2met'
            v[:formatted_time] = time.iso8601
          end
        end
      end

      def time_format
        @time_format ||= config[:time_format]
      end

      def l2met_args_to_record(l2met_args)
        args = l2met_args.dup
        ''.tap do |s|
          (builtin_l2met_args + (args.keys.sort - builtin_l2met_args)).each do |key|
            value = args.delete(key)
            value = value.inspect if value.respond_to?(:include?) && value.include?(' ')
            s << "#{key}=#{value} "
          end
        end
      end

      def builtin_l2met_args
        @builtin_l2met_args ||= %w[time level msg].map(&:to_sym)
      end

      def traditional_format
        @traditional_format ||= ''.tap do |s|
          s << '%<formatted_time>s ' if time_format
          s << '%<severity_initial>s '
          s << 'app[%<process_name>s]: ' if ENV['TRAVIS_PROCESS_NAME']
          s << 'PID=%<process_id>s ' if config[:process_id]
          s << 'TID=%<thread_id>s ' if config[:thread_id]
          s << '%<message>s'
        end
      end
    end
  end
end
