require 'bundler/setup'
require 'nokogiri'

# TODO: rename or break apart this class.
class DublinCoreReader
  attr_reader :mets
  attr_reader :identifier

  def initialize options
    @node = options[:node]
    @identifier = File.basename @node
    file = File.join(@node, 'data', 'mets.xml')
    @mets = nil
    if File.exist?(file)
      @mets = File.join(@node, 'data', 'mets.xml')
      @xml = Nokogiri::XML IO.read(@mets)
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

  def to_s
    if @mets
      [
        url,
        title.gsub(/\s+/, ' '),
      ].join(' ')
    else
      "NOT ok #{@identifier}: no METS"
    end
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

  def is_oral_history?
    'oral histories' == format
  end

  def is_newspaper?
    'newspapers' == format
  end

  def repository
    begin
      @xml.xpath('//mets:agent[@TYPE="REPOSITORY"]/mets:name', 'mets' => 'http://www.loc.gov/METS/').first.content
    rescue
      'no repository'
    end
  end

  def is_exploreuk?
    if 'University of Kentucky' == repository
      if 'newspapers' == format
        if title =~ /kentucky.*kernel/i or title =~ /blue-tail.*fly/i
          true
        else
          false
        end
      else
        true
      end
    else
      false
    end
  end
end

module Lomatia
  module Worker
    module KudlStats
      class Bag
        @queue = :lomatia
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          reader = DublinCoreReader.new(node: node)

          CSV.open(options['log'], 'a') do |csv|
            puts "KudlStats: #{reader.identifier}"
            if reader.mets
              puts "KudlStats: #{reader.identifier} mets"
              csv << [
                reader.identifier,
                '1',
                reader.type,
                reader.is_exploreuk? ? '1' : '0',
                reader.is_oral_history? ? '1' : '0',
                reader.is_newspaper? ? '1' : '0',
                reader.total_size
              ]
            else
              puts "KudlStats: #{reader.identifier} !mets"
              csv << [
                reader.identifier,
                '0',
                reader.type,
                '0',
                '0',
                '0',
                reader.total_size
              ]
            end
          end
        end
      end
    end
  end
end
