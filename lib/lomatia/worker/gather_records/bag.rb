require 'bundler/setup'
require 'nokogiri'

class DublinCoreReader
  def initialize options
    @node = options[:node]
    @identifier = File.basename @node
    @mets = File.join(@node, 'data', 'mets.xml')
    @xml = Nokogiri::XML IO.read(@mets)
  end

  def to_s
    [
      url,
      title,
    ].join(' ')
  end

  def summary
    to_s
  end
  
  def url
    "http://kdl.kyvl.org/catalog/#{@identifier}_1"
  end

  def title
    begin
      @xml.xpath('//dc:title', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content.strip
    rescue
      'no title'
    end
  end

  def source
    begin
      @xml.xpath('//dc:source', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content.strip
    rescue
      'no title'
    end
  end
end

module Lomatia
  module Worker
    module GatherRecords
      class Bag
        @queue = :lomatia
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          reader = DublinCoreReader.new(node: node)

          if options['require_source'] and reader.source == options['require_source'].strip
            puts "GatherRecords: #{reader.summary}"
            File.open(options['log'], 'a') do |f|
              f.puts reader.to_s
            end
          end
        end
      end
    end
  end
end
