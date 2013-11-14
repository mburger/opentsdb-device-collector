module Opentsdb
  module Device
    module Collector
      module Type
        class Elasticsearch
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            @port = @options['port'] || 9200
            @node_name = @options['node_name']
            @use_basic_auth = @options['use_basic_auth']
            @username = @options['username']
            @password = @options['password']
            info "[Type Elasticsearch] Initialized for: #{@hostname}"
          end

          def get_metrics
            data = []
            begin
              get_indices_stats(data)
            rescue Exception => e
              error "#{@hostname} | #{e.class} -> #{e}"
            end
            return data
          end

          def get_indices_stats(data)
            timestamp = Time.now.to_i
            resp = make_http_request("/_cluster/nodes/#{@node_name}/stats")
            node_data = resp['nodes'][@node_name]['indices']
            data << {:metric => 'elasticsearch.indices.docs.count', :timestamp => timestamp, :value => node_data['docs']['count'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.docs.deleted', :timestamp => timestamp, :value => node_data['docs']['deleted'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.store.size', :timestamp => timestamp, :value => node_data['store']['size_in_bytes'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.store.throttle', :timestamp => timestamp, :value => node_data['store']['throttle_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.indexing.index_time', :timestamp => timestamp, :value => node_data['indexing']['index_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.indexing.delete_time', :timestamp => timestamp, :value => node_data['indexing']['delete_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.total', :timestamp => timestamp, :value => node_data['get']['total'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.time', :timestamp => timestamp, :value => node_data['get']['time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.exists_total', :timestamp => timestamp, :value => node_data['get']['exists_total'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.exists_time', :timestamp => timestamp, :value => node_data['get']['exists_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.missing_total', :timestamp => timestamp, :value => node_data['get']['missing_total'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.get.missing_time', :timestamp => timestamp, :value => node_data['get']['missing_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.search.open_contexts', :timestamp => timestamp, :value => node_data['search']['open_contexts'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.search.query_total', :timestamp => timestamp, :value => node_data['search']['query_total'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.search.query_time', :timestamp => timestamp, :value => node_data['search']['query_time_in_millis'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.search.fetch_total', :timestamp => timestamp, :value => node_data['search']['fetch_total'], :tags => "host=#{@hostname}"}
            data << {:metric => 'elasticsearch.indices.search.fetch_time', :timestamp => timestamp, :value => node_data['search']['fetch_time_in_millis'], :tags => "host=#{@hostname}"}
            return data
          end

          def make_http_request(uri)
            req = Net::HTTP::Get.new(uri)
            req.basic_auth(@username, @password) if @use_basic_auth
            res = Net::HTTP.start(@hostname, @port) do |http|
              http.request(req)
            end
            JSON.parse(res.body)
          end

        end
      end
    end
  end
end
