require 'rubygems'
require 'bundler/setup'

require 'rspec'
$:.unshift '.'
require 'application'
Coupler::Application.new

include Coupler
