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

  def title
    begin
      @xml.xpath('//dc:source', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content
    rescue
      'no title'
    end
  end

  def format
    begin
      @xml.xpath('//dc:format', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content
    rescue
      'no format'
    end
  end

  def page_count
    @xml.xpath('//mets:structMap/mets:div').count
  end

  def total_pdf_size
    @xml.xpath('//mets:file[@USE="print image"]/mets:FLocat').collect { |f|
      File.size(File.join(@node, 'data', f['xlink:href']))
    }.inject(&:+)
  end

  def total_tiff_size
    @xml.xpath('//mets:file[@USE="master"]/mets:FLocat').collect { |f|
      File.size(File.join(@node, 'data', f['xlink:href']))
    }.inject(&:+)
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

  def timestamp
    Time.parse(
      @xml.xpath('//metsHdr').first['LASTMODDATE']
    ).utc.iso8601
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
    module GatherTitleStatistics
      class Bag
        @queue = :lomatia
  
        def self.perform(options)
          node = File.join(options['node'], options['path'])
          identifier = File.basename node
          bag = BagIt::Bag.new node
          log = options['log']

          if options['titles']
            titles_file = options['titles']
            title_count = `grep -c -f #{titles_file} #{File.join(node, 'data', 'mets.xml')}`.chomp.to_i

            if title_count == 0
              return
            end
          end

          analyzer = BagAnalyzer.new :node => node
          if options['format']
            unless options['format'] == analyzer.format
              return
            end
          end

          CSV.open(log, 'a') do |csv|
            puts "#{identifier}"
            csv << [
              identifier,
              node,
              analyzer.type,
              analyzer.timestamp,
              analyzer.title,
              analyzer.page_count,
              analyzer.total_pdf_size,
              analyzer.total_tiff_size,
              analyzer.total_size,
            ]
          end
        end
      end
    end
  end
end
