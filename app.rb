# encoding: utf-8
require 'sinatra/base'
require 'open-uri'
require 'json'

$LOAD_PATH.unshift ENV['APP_ROOT'] || File.expand_path('..', __FILE__)
$LOAD_PATH.unshift File.join($LOAD_PATH.first, 'lib')
require 'clam_helper'

class ClamBake < Sinatra::Base

  configure do
    @@clamav = ClamHelper.new
  end

  configure :development do
    set :logging, true
  end

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
    retries = params[:retry].to_i
    retries = 1 if retries.zero?
    raise URI::InvalidURIError, 'invalid URL given' unless url.scheme =~ /^http(s)?$/

    is_virus = @@clamav.scan_url(url, retries)

    content_type :json
    {"url" => url.to_s, "virus" => is_virus}.to_json
  end
  run! if app_file == $0
end
