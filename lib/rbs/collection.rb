require 'yaml'
require 'bundler'

require_relative './collection/collections'
require_relative './collection/config'
require_relative './collection/config/gemfile_lock_loader'
require_relative './collection/installer'
require_relative './collection/cleaner'

module RBS
  module Collection
  end
end
