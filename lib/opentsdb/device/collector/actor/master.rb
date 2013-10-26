module Opentsdb
  module Device
    module Collector
      module Actor
        class Master
          include Celluloid
          include Celluloid::Logger

          finalizer :finally

          def initialize(options)
            @options = options
            @collectors = Celluloid::SupervisionGroup.run!

            @options['devices'].each do |hostname, options|
              @collectors.add(Opentsdb::Device::Collector::Actor::Client, as: hostname.to_sym, args: [hostname, options])
            end
            Opentsdb::Device::Collector::Actor::OpentsdbClient.supervise_as(:opentsdb, @options['opentsdb'])
            Opentsdb::Device::Collector::Actor::McoClient.supervise_as(:mco, @options['mco'])
          end

          def finally
            @collectors.async.terminate
            Celluloid::Actor[:mco].async.terminate
            Celluloid::Actor[:opentsdb].async.terminate
          end

        end
      end
    end
  end
end
