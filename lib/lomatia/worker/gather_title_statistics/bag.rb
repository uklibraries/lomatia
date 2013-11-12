require 'bundler/setup'
require 'bagit'
require 'csv'
require 'nokogiri'
require 'find'

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

  def AIPs_pdf_count
    pdf_file_paths = [] 
    search_path = @node
    file_with_ext = {}
    if (Dir.glob(@node + "*.tif"))
    @xml.xpath('//mets:file[@USE="print image"]/mets:FLocat').collect { |f|
      Find.find(search_path).each do |path|  
        if File.file? path
           extension = File.extname path
           file_with_ext[extension] || = []
           file_with_ext[extension] << path
        end
      end
    }.inject(&:+)
    end   
  end

  def DIPs_pdf_count
    pdf_file_paths = [] 
    search_path = @node
    file_with_ext = {}
    if (Dir.glob(@node + "*.jpg"))
    @xml.xpath('//mets:file[@USE="print image"]/mets:FLocat').collect { |f|
      Find.find(search_path).each do |path|  
        if File.file? path
           extension = File.extname path
           file_with_ext[extension] || = []
           file_with_ext[extension] << path
        end
      end
    }.inject(&:+)
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
                analyzer.title,
                analyzer.page_count,
                analyzer.total_pdf_size,
                analyzer.total_tiff_size,
                analyzer.AIPs_pdf_count,
                analyzer.SIPs_pdf_count,
              ]
            end
          end
        end
      end
    end
  end
end
