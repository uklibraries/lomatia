require 'bundler/setup'
require 'resque'

module Lomatia
  module Branch
    def self.replant options
      source_path = File.join options['source'], options['path']

      if File.symlink? source_path
        raise Lomatia::Error::BranchAlreadyMovedError
      end

      if File.exist?(File.join source_path, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::Replant::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::Replant::Branch, options)
      end
    end
  end
end
