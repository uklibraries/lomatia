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

          validity = bag.valid? ? "valid" : "invalid"
          File.open(log, 'a') do |f|
            puts "#{identifier}: #{validity}"
            f.puts "#{identifier}: #{validity}"
          end

          if options['error'] and validity == "invalid"
            File.open(options['error'], 'a') do |f|
              f.puts '=' * 70
              f.puts identifier
              f.puts node
              f.puts 
              f.puts bag.errors.full_messages.join("\n")
              f.puts
            end
          end
        end
      end
    end
  end
end
