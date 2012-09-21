require 'clamav'

class ClamHelper

  def initialize
    @clamav = ClamAV.instance
    puts "Loading ClamAV DB"
    @clamav.loaddb
  end

  def scanfile(file)
    @clamav.scanfile(file)
  end

  def reload
    @clamav.reload
  end

end
