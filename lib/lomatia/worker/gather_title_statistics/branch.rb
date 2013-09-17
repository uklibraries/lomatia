module Lomatia
  module Worker
    module GatherTitleStatistics
      class Branch
        @queue = :lomatia
  
        def self.perform(options)
          unless File.directory?(File.join(options['node'], options['path']))
            raise Lomatia::Error::BranchNotADirectoryError
          end
  
          Dir.chdir options['node']
          Dir.glob(File.join options['path'], '*').each do |f|
            if File.directory? f
              Lomatia::Branch.gather_title_statistics options.merge(
                'path' => f
              )
            end
          end
        end
      end
    end
  end
end
