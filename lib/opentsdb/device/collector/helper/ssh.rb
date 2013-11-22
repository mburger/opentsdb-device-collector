module Opentsdb
  module Device
    module Collector
      module Helper
        class Ssh
          attr_accessor :username, :password, :hostname, :port, :default_prompt, :timeout

          def initialize(options = {})
            @hostname       = options[:hostname] unless options[:hostname].nil?
            @username       = options[:username] unless options[:username].nil?
            @password       = options[:password] unless options[:password].nil?
            @port           = options[:port] || 22
            @timeout        = options[:timeout] || 10
            @default_prompt = options[:default_prompt] || /[#>]\s?\z/n
            @debug          = options[:debug]
            @noop           = options[:noop]
          end

          def connect(&block)
            begin
              puts "Trying to connect to #{hostname} as #{username}" if @debug
              @ssh = ::Net::SSH.start(hostname, username, :port => port, :password => password, :timeout => timeout)
            rescue TimeoutError
              raise TimeoutError, "timed out while trying to connect to #{hostname}"
            rescue ::Net::SSH::AuthenticationFailed
              raise ::Net::SSH::AuthenticationFailed, "SSH auth failed while trying to connect to #{hostname} as #{username}"
            end

            @buf      = ''
            @eof      = false
            @channel  = nil
            @ssh.open_channel do |channel|
              channel.request_pty {|ch, success| raise "Failed to open PTY" unless success}

              channel.send_channel_request('shell') do |ch, success|
                raise 'Failed to open SHELL Channel' unless success

                ch.on_data {|ch, data| @buf << data}
                ch.on_extended_data {|ch, type, data| @buf << data if type == 1}
                ch.on_close {@eof = true}

                @channel = ch
                expect(default_prompt, &block)
                command('terminal length 0', :noop => false)
                return
              end
            end
            @ssh.loop
          end

          def close
            @channel.close if @channel
            @channel = nil
            @ssh.close if @ssh
          end

          def expect(prompt)
            line    = ''
            socket  = @ssh.transport.socket

            while not eof?
              break if line =~ prompt and @buf == ''
              break if socket.closed?

              IO::select([socket], [socket], nil, nil)

              process_ssh

              if @buf != ''
                line << @buf.gsub(/\r\n/no, "\n")
                @buf = ''
                yield line if block_given?
              elsif eof?
                break if line =~ prompt
                if line == ''
                  line = nil
                  yield nil if block_given?
                end
                break
              end
            end
            line
          end

          def send(line, noop = false)
            str = ""
            str += "+++ SSH (OUT) => #{line.strip}" if @debug
            str += " *** NOOP ***" if @debug && noop
            puts str unless str.empty?
            @channel.send_data(line + "\n") unless noop
          end

          def eof?
            !!@eof
          end

          def command(cmd, options = {})
            noop = (options[:noop].nil? ? @noop : options[:noop])
            raise "### Can't run Command, underlying SSH Transport already CLOSED!" if @ssh.transport.closed?
            send(cmd, noop)
            unless noop
              expect(options[:prompt] || default_prompt) do |out|
                yield out if block_given?
              end
            end
          end

          def process_ssh
            while @buf == '' and not eof?
              begin
                @channel.connection.process(0.1)
              rescue IOError
                @eof = true
              end
            end
          end
        end
      end
    end
  end
end
