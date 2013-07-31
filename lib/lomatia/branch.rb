require 'bundler/setup'
require 'resque'

module Lomatia
  module Branch
    def self.check_fixity options
      node = File.join options['node'], options['path']

      if File.exist?(File.join node, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::CheckFixity::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::CheckFixity::Branch, options)
      end
    end

    def self.repair_mets_cruft options
      node = File.join options['node'], options['path']

      if File.exist?(File.join node, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::RepairMetsCruft::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::RepairMetsCruft::Branch, options)
      end
    end

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
