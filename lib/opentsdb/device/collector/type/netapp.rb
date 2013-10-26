module Opentsdb
  module Device
    module Collector
      module Type
        class Netapp
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            start
          end

          def start
            info "[Type Netapp] Connecting to: #{@hostname}:#{@options['port']}"
            @ssh = Opentsdb::Device::Collector::Helper::Ssh.new(:hostname => @hostname,
                                                                :username => @options['username'],
                                                                :password => @options['password'],
                                                                :port     => @options['port'])
            begin
              @ssh.connect
            rescue Exception => e
              # Maybe the Device is not responding ?
              # In any case, sleep 20 seconds to delay the actor respawn
              sleep 20
              raise e
            end
          end

          def get_metrics
            data = []
            timestamp = Time.now.to_i
            metrics = [ 'ifnet:e1b:recv_packets', 'ifnet:e1b:send_packets',
                        'ifnet:e1b:recv_data', 'ifnet:e1b:send_data',
                        'nfsv3:nfs:nfsv3_ops', 'nfsv3:nfs:nfsv3_read_latency',
                        'nfsv3:nfs:nfsv3_read_ops', 'nfsv3:nfs:nfsv3_write_latency',
                        'nfsv3:nfs:nfsv3_write_ops', 'nfsv3:nfs:nfsv3_avg_op_latency',
                        'processor:processor0:processor_busy', 'processor:processor1:processor_busy',
                        'processor:processor2:processor_busy', 'processor:processor3:processor_busy',
                        'system:system:read_ops', 'system:system:sys_read_latency', 'system:system:write_ops',
                        'system:system:sys_write_latency', 'system:system:sys_avg_latency', 'wafl:wafl:wafl_memory_free',
                        'wafl:wafl:wafl_memory_used', 'ext_cache_obj:ec0:usage', 'ext_cache_obj:ec0:hit_percent',
                        'ext_cache_obj:ec0:miss' ]
            out = @ssh.command("stats show #{metrics.join(' ')}")
            metrics.each do |met|
              val = out.scan(/#{met}:(\d+)/).flatten.first
              met = met.gsub(/:/, '.')
              data << {:metric => met, :timestamp => timestamp, :value => val, :tags => "host=#{@hostname}"}
            end
            return data
          end

        end
      end
    end
  end
end
