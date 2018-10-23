class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # before_action :authorize
  skip_before_action :verify_authenticity_token

  def index
    render html: "hello, world!"
  end

  def slack_to_user
    payload = JSON.parse(request.body.read)
    response = SlackSender.new.send_message(payload['theme'], payload['title'], payload['message'], params[:user_name])
    if response.include?('ERROR:')
      render status: 400, json: {message: response}
    else
      render status: 200, json: {message: response}
    end
  end

  def slack_to_channel
    payload = JSON.parse(request.body.read)
    channel = params[:channel_name]
    channel = "##{channel}" unless channel.start_with?('#')
    response = SlackSender.new.send_message(payload['theme'], payload['title'], payload['message'], channel, false)
    if response.include?('ERROR:')
      render status: 400, json: {message: response}
    else
      render status: 200, json: {message: response}
    end
  end

  def authorize
    username = request.headers[:user]
    password = request.headers[:password]
    salt = Digest::SHA1.hexdigest("# We add #{username} as unique value and #{Time.now} as random value")
    encrypted_password = Digest::SHA1.hexdigest("Adding #{salt} to #{password}")
    # puts "#{salt} #{encrypted_password}"
    pass = username == ENV['usr'] && encrypted_password == ENV['pwd']

    render status: 401, json: {message: 'Wrong authorization!'} unless pass
  end
end
