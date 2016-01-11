# encoding: utf-8
require 'kiba/version'
require 'kiba/logger'

require 'kiba/control'
require 'kiba/context'
require 'kiba/parser'
require 'kiba/counter'
require 'kiba/runner'
require 'redis'
require 'timers'

module Kiba
  module_function

  def redis
    @redis ||= Redis.new
  end

  def timers
    @timers ||= Timers::Group.new
  end
end


Kiba.extend(Kiba::Parser)
Kiba.extend(Kiba::Runner)
