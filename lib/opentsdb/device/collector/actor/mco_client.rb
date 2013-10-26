module Opentsdb
  module Device
    module Collector
      module Actor
        class McoClient
          include Celluloid
          include Celluloid::Logger
          include MCollective::RPC

          def initialize(options)
            @options = options

            info "[Actor McoClient] Initialized"
            async.connect_nettest
          end

          def connect_nettest
            @mc_nettest = rpcclient('nettest', MCollective::Util.default_options)
            @mc_nettest.progress = false
          end

          def ping(hostname, options = {})
            @mc_nettest.timeout = options['timeout'] || 2
            @mc_nettest.fact_filter options['fact_filter'] if options['fact_filter']
            return @mc_nettest.ping(:fqdn => hostname)
          end

        end
      end
    end
  end
end
