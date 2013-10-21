require 'clamav'
require 'tempfile'
require 'zlib'

class ClamHelper

  def initialize
    @clamav = ClamAV.instance
    puts "Loading ClamAV DB"
    @clamav.loaddb
  end

  def reload
    @clamav.reload
  end

  def signo
    @clamav.signo
  end

  def scan_url(url, retries=1)
    is_virus = nil

    retries = retries > 10 ? 10 : retries
    retries.times do |c|
      if c + 1 < retries
        # blocks any errors to try again
        begin
          is_virus = self.scan_url_without_retry(url)
        rescue
          is_virus = nil
          sleep rand * 2
        end
      else
        # last attempt, dont ignore exceptions
        is_virus = self.scan_url_without_retry(url)
      end
      break unless is_virus.nil?
    end

    is_virus
  end

  def scan_url_without_retry(url)
    is_virus = nil

    open(url.to_s) do |aws_f|
      # use a consistent hash for the filename, this fixes Errno::ENAMETOOLONG
      tmp_filename = Zlib.crc32(File.basename(url.path)).to_s
      tmp_file = Tempfile.new(tmp_filename)
      begin
        tmp_file.write(aws_f.read)
        tmp_file.close
      ensure
        is_virus = @clamav.scanfile(tmp_file.path)
        tmp_file.unlink
      end
    end

    is_virus == 0 ? false : is_virus
  end

end
