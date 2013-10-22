module Opentsdb
  module Device
    module Collector
      module CLI
        class Run
          def initialize(options)
            @options = options
            @running = true

            dispatch
          end

          def dispatch
            setup_logging
            setup_traps
            setup_actors
            start_main_loop
          end

          def setup_logging
            require 'logger'
            ::Celluloid.logger = ::Logger.new(STDOUT)
          end

          def setup_traps
            # Workaround for https://github.com/celluloid/celluloid/pull/121
            output, input = IO.pipe

            Thread.new do
              while output.read(1)
                @running = false
                @master.terminate if @master
              end
            end

            [ 'TERM', 'INT' ].each do |signal|
              Signal.trap(signal) do
                input << "\0"
                sleep 1
                exit
              end
            end
          end

          def setup_actors
            @master = Opentsdb::Device::Collector::Actor::Master.supervise_as(:master, @options)
          end

          def start_main_loop
            while @running do
              sleep 1
            end
          end

        end
      end
    end
  end
end
