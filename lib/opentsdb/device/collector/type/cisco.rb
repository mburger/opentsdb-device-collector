module Opentsdb
  module Device
    module Collector
      module Type
        class Cisco
          include Celluloid::Logger

          def initialize(hostname, options)
            @hostname = hostname
            @options = options
            @interfaces = @options['interfaces'] || []
            @connected = false
            start
          end

          def start
            info "[Type Cisco] Connecting to: #{@hostname}:#{@options['port']}"
            @ssh = Opentsdb::Device::Collector::Helper::Ssh.new(:hostname => @hostname,
                                                                :username => @options['username'],
                                                                :password => @options['password'],
                                                                :port     => @options['port'])
            begin
              @ssh.connect
              @connected = true
            rescue Exception => e
              sleep 5
              retry
            end
          end

          def get_metrics
            data = []
            if @connected
              get_cpu(data)
              get_dhcp_snooping(data)
              @interfaces.each do |int|
                get_interface(int, data)
              end
            end
            return data
          end

          def get_cpu(data)
            out = @ssh.command('show processes cpu | inc utilization')
            timestamp = Time.now.to_i
            if out.match(/Core \d+:/)
              out.each_line do |line|
                case line
                when /Core (\d+): CPU utilization for five seconds: (\d+)%(?:\/\d+%)*; one minute: (\d+)%; five minutes: (\d+)%/
                  data << {:metric => 'network.cpu.utilization.5srate', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} core=#{$1}"}
                  data << {:metric => 'network.cpu.utilization.1mrate', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname} core=#{$1}"}
                  data << {:metric => 'network.cpu.utilization.5mrate', :timestamp => timestamp, :value => $4, :tags => "host=#{@hostname} core=#{$1}"}
                end
              end
            else
              out.each_line do |line|
                case line
                when /CPU utilization for five seconds: (\d+)%(?:\/\d+%)*; one minute: (\d+)%; five minutes: (\d+)%/
                  data << {:metric => 'network.cpu.utilization.5srate', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
                  data << {:metric => 'network.cpu.utilization.1mrate', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname}"}
                  data << {:metric => 'network.cpu.utilization.5mrate', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname}"}
                end
              end
            end
            return data
          end

          def get_dhcp_snooping(data)
            out = @ssh.command('sh ip dhcp snooping statistics detail')
            timestamp = Time.now.to_i
            out.each_line do |line|
              case line
              when /^\s*Packets Processed by DHCP Snooping\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.processed', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*IDB not known\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.idb', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Queue full\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.full', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Interface is in errdisabled\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.errdisabled', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Rate limit exceeded\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.ratelimit', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Received on untrusted ports\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.untrusted', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Nonzero giaddr\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.nonzerogiaddr', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Source mac not equal to chaddr\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.macnotchaddr', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*No binding entry\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.nobinding', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Insertion of opt82 fail\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.opt82fail', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Unknown packet\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.unknown', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Interface Down\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.intdown', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Unknown output interface\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.unknownout', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Misdirected Packets\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.misdirected', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Packets with Invalid Size\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.invalidsize', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              when /^\s*Packets with Invalid Option\s+=\s(\d+)\s*$/
                data << {:metric => 'network.dhcp.snooping.invalidoption', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname}"}
              end
            end
            return data
          end

          def get_interface(int, data)
            out = @ssh.command("sh int #{int}")
            timestamp = Time.now.to_i
            out.each_line do |line|
              case line
              when /5 minute input rate (\d+) bits\/sec, (\d+) packets\/sec/
                data << {:metric => 'network.interface.input.5mrate.bits', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.5mrate.packets', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
              when /5 minute output rate (\d+) bits\/sec, (\d+) packets\/sec/
                data << {:metric => 'network.interface.output.5mrate.bits', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.output.5mrate.packets', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
              when /(\d+) packets input, (\d+) bytes, (\d+) no buffer/
                data << {:metric => 'network.interface.input.bits', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.packets', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.nobuffer', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname} interface=#{int}"}
              when /(\d+) packets output, (\d+) bytes, (\d+) underruns/
                data << {:metric => 'network.interface.output.bits', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.output.packets', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.output.underruns', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname} interface=#{int}"}
              when /Received (\d+) broadcasts \((\d+) .+\)/
                data << {:metric => 'network.interface.input.broadcasts', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.multicasts', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
              when /(\d+) input errors, (\d+) CRC, (\d+) frame, (\d+) overrun, (\d+) ignored/
                data << {:metric => 'network.interface.input.errors', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.errors.crc', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.errors.frame', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.errors.overrun', :timestamp => timestamp, :value => $4, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.input.errors.ignored', :timestamp => timestamp, :value => $5, :tags => "host=#{@hostname} interface=#{int}"}
              when /(\d+) output errors, (\d+) collisions, (\d+) interface resets/
                data << {:metric => 'network.interface.output.errors', :timestamp => timestamp, :value => $1, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.output.errors.collisions', :timestamp => timestamp, :value => $2, :tags => "host=#{@hostname} interface=#{int}"}
                data << {:metric => 'network.interface.output.errors.resets', :timestamp => timestamp, :value => $3, :tags => "host=#{@hostname} interface=#{int}"}
              end
            end
          end

        end
      end
    end
  end
end
