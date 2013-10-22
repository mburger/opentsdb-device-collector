module Opentsdb
  module Device
    module Collector
      module Type
        class Fping
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @ping_count = options['ping_count'] || 3
          end

          def get_metrics
            data = []
            info "[Type Fping] Running fping for: #{@hostname}"
            out = `bash -c 'fping -c #{@ping_count} -sq #{@hostname} 2>&1'`
            timestamp = Time.now.to_i
            out.each_line do |line|
              case line
              when /xmt\/rcv\/%loss = (\d+)\/(\d+)\/(\d+)%/
                data << {:metric => 'fping.xmt', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
                data << {:metric => 'fping.rcv', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname}"}
                data << {:metric => 'fping.loss', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname}"}
              when /(\d+\.*\d*) ms \(min round trip time\)/
                data << {:metric => 'fping.min', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /(\d+\.*\d*) ms \(avg round trip time\)/
                data << {:metric => 'fping.avg', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /(\d+\.*\d*) ms \(max round trip time\)/
                data << {:metric => 'fping.max', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              end
            end
            return data
          end

        end
      end
    end
  end
end
