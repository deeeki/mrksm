module Mrksm
  module Downloader
    module_function
    def save_image file, image_url
      return puts "exists #{file}" if File.exists?(file)
      image = AGENT.get(image_url)
      return puts "not image #{image_url}" if image.response['content-type'] !~ /\Aimage/
      image.save(file)
      puts "downloaded #{image_url} -> #{file}"
    end

    def download_entry entry, options = {}
      return "#{entry.url} has no image" if entry.images.empty?
      dir = options.delete(:dir) || 'images'
      entry_dir = "#{dir}/#{entry.date.strftime('%Y%m%d')}_#{entry.slug.slice(6, 2)}"
      FileUtils.mkdir_p(entry_dir) unless Dir.exists?(entry_dir)
      entry.images.each{|img| save_image("#{entry_dir}/#{File.basename(img)}", img) }
    end

    def download_latest options = {}
      log, latest_slug = Log.new, nil
      Entry.latest_urls.each do |url|
        entry = Entry.new(url)
        latest_slug ||= entry.slug
        break if log.slug && entry.slug <= log.slug
        download_entry(entry, options)
      end
      if latest_slug == log.slug
        puts 'not updated'
      else
        log.write(latest_slug)
      end
    end

    def download_all options = {}
      Entry.monthly_first_urls(options).each do |url|
        loop do # until entry is not found in current month
          entry = Entry.new(url)
          break if entry.not_found?
          download_entry(entry, options)
          url = entry.next_url
        end
      end
    end
  end
end
