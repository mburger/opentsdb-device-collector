module Opentsdb
  module Device
    module Collector
      module Actor
        class OpentsdbClient
          include Celluloid::IO
          include Celluloid::Logger

          finalizer :finally

          def initialize(options)
            @options = options

            info "[Actor OpentsdbClient] Connecting to: #{@options['host']}:#{@options['port']}"
            async.connect
          end

          def connect
            # delay the reconnect attempts if the actor crashes
            sleep 1
            @socket = TCPSocket.new(@options['host'], @options['port'])
          end

          def put(options = {})
            timestamp = options[:timestamp].to_i || Time.now.to_i
            metric_name = options[:metric]
            value = options[:value].to_f
            tags = options[:tags] || ""
            @socket.puts("put #{metric_name} #{timestamp} #{value} #{tags}")
          end

          def finally
            @socket.close if @socket && !@socket.closed?
          end

        end
      end
    end
  end
end
