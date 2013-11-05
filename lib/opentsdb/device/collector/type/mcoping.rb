module Opentsdb
  module Device
    module Collector
      module Type
        class Mcoping
          include Celluloid::Logger
          include MCollective::RPC

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            info "[Type Mcoping] Initialized for: #{@hostname}"
          end

          def get_metrics
            pings = Celluloid::Actor[:mco].future.ping(@hostname, @options)
            data = []
            timestamp = Time.now.to_i
            tmp = {}
            tmp[:count] = 0
            tmp[:rtt] = []
            pings.value.each do |resp|
              val = (resp[:data][:rtt] || 0)
              tmp[:rtt] << val
              tmp[:count] += 1
              data << {:metric => 'mcoping.rsp', :timestamp => timestamp, :value => val, :tags => "host=#{@hostname} mcohost=#{resp[:sender]}"}
              data << {:metric => 'mcoping.statuscode', :timestamp => timestamp, :value => resp[:statuscode], :tags => "host=#{@hostname} mcohost=#{resp[:sender]}"}
            end
            unless tmp[:rtt].empty? || tmp[:rtt].nil? || (tmp[:count] == 0)
              max_rtt = tmp[:rtt].max
              min_rtt = tmp[:rtt].min
              avg_rtt = (tmp[:rtt].inject(:+) / tmp[:count])
              data << {:metric => 'mcoping.max', :timestamp => timestamp, :value => max_rtt, :tags => "host=#{@hostname}"}
              data << {:metric => 'mcoping.min', :timestamp => timestamp, :value => min_rtt, :tags => "host=#{@hostname}"}
              data << {:metric => 'mcoping.avg', :timestamp => timestamp, :value => avg_rtt, :tags => "host=#{@hostname}"}
            end
            return data
          end

        end
      end
    end
  end
end
