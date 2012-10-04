require 'clamav'

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

  def scan_url(url)
    is_virus = nil

    open(url.to_s) do |aws_f|
      tmp_filename = File.basename(url.path)
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
