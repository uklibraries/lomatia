require 'bundler/setup'
require 'bagit'

module Lomatia
  module Worker
    module CheckFixity
      class Bag
        @queue = :lomatia
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          bag = BagIt::Bag.new node
          log = options['log']
          puts log

          File.open(log, 'a') do |f|
            f.puts "#{identifier}: #{bag.valid? ? "valid" : "invalid"}"
          end
        end
      end
    end
  end
end
