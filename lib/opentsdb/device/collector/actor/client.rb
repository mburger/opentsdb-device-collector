module Opentsdb
  module Device
    module Collector
      module Actor
        class Client
          include Celluloid
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            async.connect
            async.start
          end

          def connect
            @collector_types = {}
            @options['types'].each do |type, options|
              @collector_types[type] = Opentsdb::Device::Collector::Type.const_get(type.capitalize).new(@hostname, options)
            end
          end

          def start
            @options['types'].each do |type, options|
              every(options['interval']) do
                @collector_types[type].get_metrics.each do |metric|
                  Celluloid::Actor[:opentsdb].async.put(metric)
                end
              end
            end
          end

        end
      end
    end
  end
end
