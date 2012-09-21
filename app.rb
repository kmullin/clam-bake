# encoding: utf-8
require 'sinatra/base'
require 'open-uri'
require 'tempfile'
require 'json'

$LOAD_PATH.unshift ENV['APP_ROOT'] || File.expand_path('..', __FILE__)
$LOAD_PATH.unshift File.join($LOAD_PATH.first, 'lib')
require 'clam_helper'

class ClamBake < Sinatra::Base

  configure :development do
    set :logging, true
  end

  @@clamav = ClamHelper.new

  get "/" do
    erb :index
  end

  get "/info" do
    content_type :json
    {"signatures" => @@clamav.signo}.to_json
  end

  get "/virus_test" do
    send_file File.join(settings.public_folder, 'virus')
  end

  put "/reload" do
    reloaded = @@clamav.reload
    content_type :json
    {"reloaded" => !reloaded.zero?}.to_json
  end

  post "/scan" do
    bad_request = false
    begin
      url = URI.parse(params[:url])
      bad_request = true unless url.scheme =~ /^http(s)?$/
    rescue URI::InvalidURIError
      bad_request = true
    end

    if bad_request
      status 400
      return
    end

    is_virus = nil
    begin
      open(url.to_s) do |aws_f|
        tmp_filename = File.basename(url.path)
        tmp_file = Tempfile.new(tmp_filename)
        begin
          tmp_file.write(aws_f.read)
          tmp_file.close
        ensure
          is_virus = @@clamav.scanfile(tmp_file.path)
          tmp_file.unlink
        end
      end
    rescue OpenURI::HTTPError => eie
      status eie.io.status[0]
      return
    rescue Errno::ECONNREFUSED
      status 500
      return
    end

    is_virus = is_virus == 0 ? false : is_virus

    content_type :json
    {"url" => url.to_s, "virus" => is_virus}.to_json
  end
  run! if app_file == $0
end
