require 'slack-ruby-bot'
require 'active_record'
require_relative 'application_helper'

class SlackSender
  AUTHOR_TABLE = 'test_management_author'

  def initialize
    Slack.configure do |config|
      config.token = ENV['BDD_BOT_SLACK_TOKEN']
    end

    @client = Slack::Web::Client.new

    @client.auth_test
  end

  def send_message(theme, title, word, channel, is_a_user = true)
    slack_id = is_a_user ? find_uer_id(channel, title) : channel
    return "ERROR: Cannot find a slack user id for git user: #{channel}!" if slack_id == 'NOT_DEFINED'

    attachments = [{:color => theme, :title => title, :text => word}]
    status = "Notification has been sent to the #{channel}!"
    begin
      @client.chat_postMessage(channel: slack_id, as_user: true, attachments: attachments)
    rescue StandardError => e
      status = "ERROR: #{e}"
    end
    status
  end

  def find_uer_id(user, title)
    result = 'NOT_DEFINED'
    criteria = {github_name: {comparison_operator: 'EQ', attribute_value_list: [user]}}
    info = ApplicationHelper.dynamodb_get_items(AUTHOR_TABLE, criteria)
    if info.size<1
      new_record = {github_name: user, slack_id: 'NOT_DEFINED', first_time_title: title, first_time: Time.now.to_s}
      ApplicationHelper.dynamodb_put_item(AUTHOR_TABLE, new_record)
    else
      result = info[0]['slack_id']
    end
    result
  end

  def user_lists
    result = {}
    @client.users_list['members'].each {|c| result[c['name']]=c['id']}
    result
  end

  def channel_lists
    result = {}
    @client.channels_list['channels'].each {|c| result[c['name']]=c['id']}
    result
  end

end