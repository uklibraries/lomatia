require 'bundler/setup'
require 'resque'

module Lomatia
  module Branch
    # TODO merge all these methods into something simpler
    def self.gather_records options
      node = File.join options['node'], options['path']

      if File.exist?(File.join node, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::GatherRecords::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::GatherRecords::Branch, options)
      end
    end

    def self.gather_repository_statistics options
      node = File.join options['node'], options['path']

      if File.exist?(File.join node, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::GatherRepositoryStatistics::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::GatherRepositoryStatistics::Branch, options)
      end
    end

    def self.gather_title_statistics options
      node = File.join options['node'], options['path']

      if File.exist?(File.join node, 'bagit.txt')
        Resque.enqueue(Lomatia::Worker::GatherTitleStatistics::Bag, options)
      else
        Resque.enqueue(Lomatia::Worker::GatherTitleStatistics::Branch, options)
      end
    end

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
