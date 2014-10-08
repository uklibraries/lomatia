require 'bundler/setup'
require 'bagit'
require 'find'
require 'json'
require 'logger'
require 'pairtree'

module Lomatia
  module Worker
    module CleanSolr
      class Bag
        @queue = :lomatia

        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          log_file = File.open(options['log'], File::WRONLY | File::APPEND)
          logger = Logger.new log_file

          source_tree = Pairtree.at(options['solr_source'], create: true)
          source_path = source_tree.get(identifier).path

          target_tree = Pairtree.at(options['solr_target'], create: true)

          if File.directory? source_path
            Find.find(source_path) do |path|
              if File.file? path
                begin
                  original = JSON.parse(IO.read path)
                rescue JSON::ParserError
                  logger.warn "CleanSolr: #{path} not valid JSON"
                  next
                end

                base = File.basename path
                normalized = self.normalize original

                if normalized == original
                  message = "CleanSolr: #{base} unchanged"
                  logger.debug message
                  puts message
                else
                  target_path = target_tree.mk(identifier).path
                  output = File.join(target_path, base)
                  File.open(output, 'w') do |f|
                    f.write normalized.to_json
                  end
                  message = "CleanSolr: #{base} updated -> #{output}"
                  logger.info message
                  puts message
                end
              end
            end
          else
            logger.warn "CleanSolr: no such directory: #{source_path}"
          end
        end

        # borrowed from kdl-helpers
        def self.normalize thing
          # I know it is not idiomatic Ruby
          # to care about specific classes.
          #
          # However, my use case specifically involves
          # a Hash whose values are known to be Arrays (of String),
          # Strings, TrueClasses, and FalseClasses.
          if thing.class == Hash
            result = {}
            thing.each_pair do |key, value|
              result[key] = normalize value
            end
            result
          elsif thing.class == Array
            thing.collect do |item|
              normalize item
            end
          elsif thing.class == String
            thing.tr("\u0000-\u001f\u007f\u0080-\u009f", ' ').gsub(/\s+/, ' ')
          else
            thing
          end
        end
      end
    end
  end
end
