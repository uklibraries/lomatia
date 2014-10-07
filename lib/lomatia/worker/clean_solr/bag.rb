require 'bundler/setup'
require 'bagit'
require 'find'
require 'json'
require 'pairtree'

module Lomatia
  module Worker
    module CleanSolr
      class Bag
        @queue = :lomatia

        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node

          source_tree = Pairtree.at(options['solr_source'], create: true)
          source_path = source_tree.get(identifier).path

          target_tree = Pairtree.at(options['solr_target'], create: true)

          Find.find(source_path) do |path|
            if File.file? path
              base = File.basename path
              original = JSON.parse(IO.read path)
              normalized = self.normalize original

              if normalized == original
                puts "CleanSolr: #{base} unchanged"
              else
                target_path = target_tree.mk(identifier).path
                output = File.join(target_path, base)
                File.open(output, 'w') do |f|
                  f.write normalized.to_json
                end
                puts "CleanSolr: #{base} updated -> #{output}"
              end
            end
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
