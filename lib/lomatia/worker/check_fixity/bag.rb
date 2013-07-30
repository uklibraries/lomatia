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

          File.open(log, 'a') do |f|
            validity = bag.valid? ? "valid" : "invalid"
            puts "#{identifier}: #{validity}"
            f.puts "#{identifier}: #{validity}"
          end
        end
      end
    end
  end
end
