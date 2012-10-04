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

  error do
    content_type :json
    status 400

    e = env['sinatra.error']
    case e
    when Errno::ECONNRESET
      status 500
    when Errno::ECONNREFUSED
      status 500
    when OpenURI::HTTPError
      status e.io.status[0]
    end

    {:result => e.class, :message => e.message}.to_json
  end

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
    url = URI.parse(params[:url])
    raise URI::InvalidURIError, 'invalid URL given' unless url.scheme =~ /^http(s)?$/

    is_virus = nil
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

    is_virus = is_virus == 0 ? false : is_virus

    content_type :json
    {"url" => url.to_s, "virus" => is_virus}.to_json
  end
  run! if app_file == $0
end
