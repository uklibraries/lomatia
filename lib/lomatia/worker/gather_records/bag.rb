require 'bundler/setup'
require 'nokogiri'

# TODO: rename or break apart this class.
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

  def format
    begin
      @xml.xpath('//dc:format', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content.strip
    rescue
      'no format'
    end
  end

  def lccn
    begin
      sip_id = @xml.xpath('//mets:altRecordID[@TYPE="DLXS"]', 'mets' => 'http://www.loc.gov/METS/').first.content.strip
      pieces = sip_id.split('_')
      pieces[1]
    rescue
      'no lccn'
    end
  end

  def is_finding_aid?
    fa = @xml.xpath('//mets:fileGrp[@ID="FileGrpFindingAid"]')
    fa and fa.count > 0
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

          if options['all']
            puts "GatherRecords: #{reader.summary}"
            File.open(options['log'], 'a') do |f|
              f.puts reader.to_s
            end
          elsif options['require_source'] and reader.source == options['require_source'].strip
            puts "GatherRecords: #{reader.summary}"
            File.open(options['log'], 'a') do |f|
              f.puts reader.to_s
            end
          elsif options['require_lccn'] and options['require_lccn'].include?(reader.lccn)
            puts "GatherRecords: #{reader.summary}"
            File.open(options['log'], 'a') do |f|
              f.puts reader.to_s
            end
          elsif options['require_finding_aid'] and reader.is_finding_aid?
            puts "GatherRecords: #{reader.summary}"
            File.open(options['log'], 'a') do |f|
              f.puts reader.to_s
            end
          elsif options['require_format'] and reader.format == options['require_format']
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
