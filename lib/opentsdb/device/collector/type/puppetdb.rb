module Opentsdb
  module Device
    module Collector
      module Type
        class Puppetdb
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            @port = @options['port'] || 8080
            @ssl = @options['ssl'] || false
            @timeout = @options['timeout'] || 5
            @http = Net::HTTP.new(@hostname, @port)
            @http.open_timeout = @timeout
            @http.read_timeout = @timeout
            if @ssl
              @ssl_cert = OpenSSL::X509::Certificate.new(File.read(@options['ssl_cert']))
              @ssl_key = OpenSSL::PKey::RSA.new(File.read(@options['ssl_key']))
              @http.use_ssl = true
              @http.cert = @ssl_cert
              @http.key = @ssl_key
              @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            info "[Type Puppetdb] Initialized for: #{@hostname}"
          end

          def get_metrics
            data = []
            begin
              get_command_discarded(data)
              get_command_fatal(data)
              get_command_processed(data)
              get_command_processing_time(data)
              get_command_retried(data)
              get_bonecp(data)
              get_jvm_memory(data)
              get_queue_size(data)
            rescue Exception => e
              error "#{@hostname} | #{e.class} -> #{e}"
            end
            return data
          end

          def get_command_discarded(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.puppetlabs.puppetdb.command:type=global,name=discarded')
            data << {:metric => 'puppetdb.command.discard', :timestamp => timestamp, :value => resp['Count'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_command_fatal(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.puppetlabs.puppetdb.command:type=global,name=fatal')
            data << {:metric => 'puppetdb.command.fatal', :timestamp => timestamp, :value => resp['Count'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_command_processed(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.puppetlabs.puppetdb.command:type=global,name=processed')
            data << {:metric => 'puppetdb.command.processed', :timestamp => timestamp, :value => resp['Count'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_command_processing_time(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.puppetlabs.puppetdb.command:type=global,name=processing-time')
            data << {:metric => 'puppetdb.command.processing.1mrate', :timestamp => timestamp, :value => resp['OneMinuteRate'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.min', :timestamp => timestamp, :value => resp['Min'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.mean', :timestamp => timestamp, :value => resp['Mean'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.50', :timestamp => timestamp, :value => resp['50thPercentile'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.75', :timestamp => timestamp, :value => resp['75thPercentile'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.95', :timestamp => timestamp, :value => resp['95thPercentile'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.98', :timestamp => timestamp, :value => resp['98thPercentile'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.99', :timestamp => timestamp, :value => resp['99thPercentile'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.command.processing.percentile.999', :timestamp => timestamp, :value => resp['999thPercentile'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_command_retried(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.puppetlabs.puppetdb.command:type=global,name=retried')
            data << {:metric => 'puppetdb.command.retried', :timestamp => timestamp, :value => resp['Count'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_bonecp(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/com.jolbox.bonecp:type=BoneCP')
            data << {:metric => 'puppetdb.bonecp.connwait', :timestamp => timestamp, :value => (resp['CumulativeConnectionWaitTime'].to_f / 1000), :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.bonecp.statementprepare', :timestamp => timestamp, :value => (resp['CumulativeStatementPrepareTime'].to_f / 1000), :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.bonecp.statementexecution', :timestamp => timestamp, :value => (resp['CumulativeStatementExecutionTime'].to_f / 1000), :tags => "host=#{@hostname}"}
            return data
          end

          def get_jvm_memory(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/java.lang:type=Memory')
            data << {:metric => 'puppetdb.jvm.heapused', :timestamp => timestamp, :value => resp['HeapMemoryUsage']['used'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.jvm.heapmax', :timestamp => timestamp, :value => resp['HeapMemoryUsage']['max'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.jvm.heapcommited', :timestamp => timestamp, :value => resp['HeapMemoryUsage']['commited'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.jvm.nonheapused', :timestamp => timestamp, :value => resp['NonHeapMemoryUsage']['used'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.jvm.nonheapmax', :timestamp => timestamp, :value => resp['NonHeapMemoryUsage']['max'], :tags => "host=#{@hostname}"}
            data << {:metric => 'puppetdb.jvm.nonheapcommited', :timestamp => timestamp, :value => resp['NonHeapMemoryUsage']['commited'], :tags => "host=#{@hostname}"}
            return data
          end

          def get_queue_size(data)
            timestamp = Time.now.to_i
            resp = make_http_request('/v1/metrics/mbean/org.apache.activemq:BrokerName=localhost,Type=Queue,Destination=com.puppetlabs.puppetdb.commands')
            data << {:metric => 'puppetdb.queue.size', :timestamp => timestamp, :value => resp['QueueSize'], :tags => "host=#{@hostname}"}
            return data
          end

          def make_http_request(uri)
            JSON.parse(@http.get(uri).body)
          end

        end
      end
    end
  end
end
