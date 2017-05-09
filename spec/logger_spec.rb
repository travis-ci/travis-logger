require 'stringio'

describe Travis::Logger do
  let(:io)     { StringIO.new }
  let(:log)    { io.string }
  let(:logger) { Travis::Logger.new(io) }

  before :each do
    Travis.stubs(:config).returns(log_level: :info)
  end

  describe 'error' do
    context 'with exception' do
      let(:exception) { StandardError.new('kaputt!').tap { |e| e.set_backtrace(['line 1', 'line 2']) } }

      it 'logs the exception message' do
        logger.error(exception)
        expect(io.string).to include('kaputt!')
      end

      it 'logs the backtrace' do
        logger.error(exception)
        expect(io.string).to include("line 1")
        expect(io.string).to include("line 2")
      end
    end
  end
end
