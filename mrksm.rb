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
      File.open(LOG, 'w'){|f| f.puts '1970-01-01' } unless File.exist?(LOG)
    end

    def write_log log
      File.open(LOG, 'w'){|f| f.puts log }
    end

    def latest_downloaded_date
      @latest_downloaded_date ||= Date.parse(IO.read(LOG).chomp) rescue Date.new
    end

    def save(image_url, path)
      file = "#{@dir}/#{path}"
      dir = File.dirname(file)

      FileUtils.mkdir_p(dir) unless Dir.exists?(dir)
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
      unless @entry.date > latest_downloaded_date
        puts 'not updated'
        return
      end
      start_date = @entry.date
      begin
        dir = @entry.date.strftime('%Y%m%d')
        @entry.images.each_with_index do |img, i|
          path = "#{dir}/#{sprintf('%02d', i + 1)}#{File.extname(img)}"
          save(img, path)
        end
        @entry = @entry.previous_url ? Entry.new(@entry.previous_url) : nil
      end while @entry && @entry.date > latest_downloaded_date
      write_log start_date
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
