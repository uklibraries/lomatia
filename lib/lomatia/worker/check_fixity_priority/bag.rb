require 'bundler/setup'
require 'bagit'

module Lomatia
  module Worker
    module CheckFixityPriority
      class Bag
        @queue = :priority
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          bag = BagIt::Bag.new node
          log = options['log']
          bag_log = File.join bag.bag_dir, 'log.txt'

          validity = bag.valid? ? "valid" : "invalid"
          File.open(log, 'a') do |f|
            puts "#{identifier}: #{validity}"
            f.puts "#{identifier}: #{validity}"
          end
          File.open(bag_log, 'a') do |f|
            f.puts "#{Time.now.getutc} bag validity: #{validity}"
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
