module Opentsdb
  module Device
    module Collector
      module Type
        class Tsd
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            info "[Type TSD] Initialized for: #{@hostname}"
            start
          end

          def start
            # delay the reconnect attempts if the actor crashes
            sleep 1
            @socket = TCPSocket.new(@hostname, @options['port'])
          end

          def get_metrics
            data = []
            @socket.puts 'stats'
            begin
              Timeout::timeout(5) do
                loop do
                  line = @socket.readline
                  case line
                  when /^(\S+) (\d+) (\d+) (.+)/
                    data << {:metric => $1, :timestamp => $2, :value => $3, :tags => $4}
                  end
                end
              end
            rescue
            end
            return data
          end

        end
      end
    end
  end
end
