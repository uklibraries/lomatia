module Lomatia
  module Worker
    module RepairMetsCruft
      class Branch
        @queue = :repair
  
        def self.perform(options)
          unless File.directory?(File.join(options['node'], options['path']))
            raise Lomatia::Error::BranchNotADirectoryError
          end
  
          Dir.chdir options['node']
          Dir.glob(File.join options['path'], '*').each do |f|
            if File.directory? f
              Lomatia::Branch.repair_mets_cruft options.merge(
                'path' => f
              )
            end
          end
        end
      end
    end
  end
end
