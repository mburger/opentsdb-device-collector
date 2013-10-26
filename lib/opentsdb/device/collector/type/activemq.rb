module Opentsdb
  module Device
    module Collector
      module Type
        class Activemq
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            info "[Type Activemq] Initialized for: #{@hostname}"
            start
          end

          def start
            @conn = Stomp::Connection.open(@options['username'], @options['password'], @options['host'], @options['port'], true)
            @parser = Nori.new(:parser => :rexml)
            @conn.subscribe("/queue/opentsdb.statresults", { "transformation" => "jms-map-xml"})
          end

          def get_metrics
            data = []
            timestamp = Time.now.to_i
            running = true
            @conn.publish("/queue/ActiveMQ.Statistics.Broker", "", {"reply-to" => "/queue/opentsdb.statresults"})
            Timeout::timeout(5) do
              while running
                rsp = @conn.poll
                unless rsp.nil?
                  stats = @parser.parse(rsp.body)
                  stats['map']['entry'].delete_if {|ele| ele['string'].is_a?(Array) }.each do |ele|
                    metric = 'activemq.' + ele.delete('string').downcase
                    value = ele.values.first
                    data << {:metric => metric, :timestamp => timestamp, :value => value, :tags => "host=#{@hostname}"}
                  end
                  running = false
                end
              end
            end
            return data
          end

        end
      end
    end
  end
end
