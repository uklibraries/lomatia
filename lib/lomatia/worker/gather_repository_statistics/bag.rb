require 'bundler/setup'
require 'bagit'
require 'csv'
require 'find'
require 'nokogiri'
require 'time'

class BagAnalyzer
  def initialize options
    @node = options[:node]
    @mets = File.join(@node, 'data', 'mets.xml')
    @xml = Nokogiri::XML IO.read(@mets)
  end

  def repository
    begin
      @xml.xpath('//mets:agent[@TYPE="REPOSITORY"]/mets:name', 'mets' => 'http://www.loc.gov/METS/').first.content
    rescue
      'no repository'
    end
  end

  def total_size
    size = 0
    Find.find(@node) do |path|
      if File.file? path
        size += File.size(path)
      end
    end
    size
  end

  # This method of distinguishing AIPs from DIPs does NOT
  # generalize to arbitrarily-named nodes, but it works 
  # for the naming scheme used for nodes in the KUDL system.
  #
  # --mps 2014-01-14
  def type
    if @node.include? 'aips'
      'aip'
    else
      'dip'
    end
  end
end

module Lomatia
  module Worker
    module GatherRepositoryStatistics
      class Bag
        @queue = :lomatia
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          bag = BagIt::Bag.new node
          log = options['log']

          analyzer = BagAnalyzer.new :node => node
          CSV.open(log, 'a') do |csv|
            puts "#{identifier}"
            csv << [
              identifier,
              node,
              analyzer.type,
              analyzer.repository,
              analyzer.total_size,
            ]
          end
        end
      end
    end
  end
end
