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
    @xml.xpath('//dc:source', 'dc' => 'http://purl.org/dc/elements/1.1/').first.content
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
  # generalize to arbitrary objects in the KUDL repository,
  # but it works for the born-PDF newspaper objects for which
  # it was intended.  At the time this comment was written,
  # the METS profile for KUDL objects did not require that
  # AIP/DIP type be declared within the METS file.
  #
  # --mps 2013-11-14
  def type
    result = 'aip'
    Find.find(File.join(@node, 'data')) do |path|
      if File.file? path
        if '.jpg' == File.extname(path)
          result = 'dip'
          break
        end
      end
    end
    result
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
          titles_file = options['titles']

          title_count = `grep -c -f #{titles_file} #{File.join(node, 'data', 'mets.xml')}`.chomp.to_i

          if title_count > 0
            analyzer = BagAnalyzer.new :node => node
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
end
