require 'digest/md5'
require 'bundler/setup'
require 'bagit'

module Lomatia
  module Worker
    module RepairMetsCruft
      class Bag
        @queue = :repair
        CRUFT = 'mets.xml.bak'
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          bag = BagIt::Bag.new node

          if bag.paths.include? CRUFT
            bag.remove_file CRUFT

            bag.manifest_files.each do |f|
              lines = File.readlines(f).reject do |f|
                f =~ /\s+data\/#{CRUFT}\s*/
              end

              File.open("#{f}.tmp", 'w') do |io|
                lines.each {|line| io.write line}
              end

              FileUtils.mv "#{f}.tmp", f
            end
          end
        end
      end
    end
  end
end
