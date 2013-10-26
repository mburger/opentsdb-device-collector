# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentsdb/device/collector/version'

Gem::Specification.new do |spec|
  spec.name          = "opentsdb-device-collector"
  spec.version       = Opentsdb::Device::Collector::VERSION
  spec.authors       = ["Markus Burger"]
  spec.email         = ["markus.burger@uni-ak.ac.at"]
  spec.summary       = "OpenTSDB Collector for various Networkdevice Types"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "celluloid"
  spec.add_dependency "celluloid-io"
  spec.add_dependency "net-ssh"
  spec.add_dependency "mcollective-client"
  spec.add_dependency "stomp", "1.2.16"
  spec.add_dependency "nori"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
