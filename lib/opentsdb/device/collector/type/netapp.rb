module Opentsdb
  module Device
    module Collector
      module Type
        class Netapp
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            @connected = false
          end

          def start
            info "[Type Netapp] Connecting to: #{@hostname}:#{@options['port']}"
            @ssh = Opentsdb::Device::Collector::Helper::Ssh.new(:hostname => @hostname,
                                                                :username => @options['username'],
                                                                :password => @options['password'],
                                                                :port     => @options['port'])
            begin
              @ssh.connect
              @connected = true
            rescue Exception => e
              error "#{@hostname} | #{e.class} -> #{e}"
            end
          end

          def get_metrics
            data = []
            start unless @connected
            if @connected
              timestamp = Time.now.to_i
              out = @ssh.command("stats show #{@options['metrics'].join(' ')}")
              @options['metrics'].each do |met|
                val = out.scan(/#{met}:(\d+)/).flatten.first
                met = met.gsub(/:/, '.')
                data << {:metric => "netapp.#{met}", :timestamp => timestamp, :value => val, :tags => "host=#{@hostname}"}
              end
            end
            return data
          end

        end
      end
    end
  end
end
