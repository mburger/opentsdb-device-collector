#!/usr/bin/env ruby

$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require 'yaml'
require 'optparse'
require 'opentsdb/device/collector'
require 'opentsdb/device/collector/cli/run'

options = { :daemonize => false }

opts = OptionParser.new do |opts|
  opts.banner = <<-EOF
Usage:
opentsdb_device_collector [-c <config file> ] [-d]

Options:
EOF
  opts.on("-cCONFIG", "--config-file CONFIG", "Configuration File") do |op|
    options[:config] = op
  end
  opts.on("-d", "--daemonize", "Daemonize") do |op|
    options[:daemonize] = op
  end
  opts.on("-h", "--help", "Show this Message") do |op|
    puts opts
  end
end

opts.parse!

if options[:config].nil?
  puts "Missing option: --config-file"
  raise OptionParser::MissingArgument
end

if File.exists?(options[:config])
  options.merge!(YAML::load_file(options[:config]))
else
  puts "Specified Config File: #{options[:config]} does not exist!"
  exit 1
end

Opentsdb::Device::Collector::CLI::Run.new(options)
