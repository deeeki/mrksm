# coding: utf-8
require 'fileutils'
require 'bundler/setup'
Bundler.require(:default) if defined?(Bundler)

module Mrksm
  BLOG = 'http://blog.mariko-shinoda.net'
  LOG = './downloaded'
  AGENT = Mechanize.new

  def self.get(dir)
    mrksm = Downloader.new(:dir => dir)
    mrksm.process
  end

  class Entry
    attr_reader :url

    def self.latest_url
      page = AGENT.get(BLOG)
      page.at('a.title')['href'] if page
    end

    def initialize url
      @url = url
      @page = AGENT.get(url)
    end

    def date
      @date ||= (elm = @page.at('h2.date')) ? Date.strptime(elm.text, "%Y年%m月%d日") : nil
    end

    def slug
      @slug ||= "#{File.basename(@url, '.*')}"
    end

    def images
      @images ||= @page.at('.blogbody').search('img[width!="20"]').map do |img|
        img['src'].sub('-300x300', '').sub('-thumbnail2', '')
      end
    end

    def previous_url
      if @url =~ /post-82\.html$/
        return 'http://blog.mariko-shinoda.net/2012/01/post-81.html'
      end
      @previous_url ||= (elm = @page.at('a.previous')) ? elm['href'] : nil
    end
  end

  class Downloader
    def initialize(opt = {})
      @dir = opt[:dir] || 'images'
    end

    def save(image_url, file)
      image = AGENT.get(image_url)
      if image.response['content-type'] =~ /^image/
        unless File.exists?(file)
          image.save(file)
          puts "downloaded #{image_url} -> #{file}"
        else
          puts "exists #{file}"
        end
      end
    end

    def process
      @entry = Entry.new Entry.latest_url
      @log = Log.new
      if @entry.date < @log.date || @entry.slug == @log.slug
        puts 'not updated'
        return
      end
      beginning_log = "#{@entry.date},#{@entry.slug}"
      begin
        dir = "#{@dir}/#{@entry.date.strftime('%Y%m%d')}_#{@entry.slug}"
        FileUtils.mkdir_p(dir) unless Dir.exists?(dir)
        @entry.images.each_with_index do |img, i|
          file = "#{dir}/#{sprintf('%02d', i + 1)}#{File.extname(img)}"
          save(img, file)
        end
        @entry = @entry.previous_url ? Entry.new(@entry.previous_url) : nil
      end while @entry && @entry.date >= @log.date && @entry.slug != @log.slug
      @log.write beginning_log
    end
  end

  class Log
    attr_reader :date, :slug

    def initialize
      File.open(LOG, 'w'){|f| f.puts '1970-01-01,""' } unless File.exist?(LOG)
      date_str, @slug = read
      @date = Date.parse(date_str) rescue Date.new
    end

    def read
      IO.read(LOG).chomp.split(',')
    end

    def write log
      File.open(LOG, 'w'){|f| f.puts log }
    end
  end
end

if $0 == __FILE__
  require 'optparse'
  parser = OptionParser.new
  opt = {}
  parser.banner = "Usage: #{File.basename($0)} options"
  parser.on('-d DIR','--dir DIR', 'Directory path name to save image.') {|d| opt[:dir] = d }
  parser.on('-h', '--help', 'Prints this message and quit') {
    puts parser.help
    exit 0;
  }

  begin
    parser.parse!(ARGV)
  rescue OptionParser::ParseError => e
    $stderr.puts e.message
    $stderr.puts parser.help
    exit 1
  else
    Mrksm.get(opt[:dir])
  end
end
