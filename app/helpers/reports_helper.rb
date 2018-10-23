require 'aws-sdk'
require 'tempfile'
require 'json'
require 'active_support/core_ext/date/calculations'

module ReportsHelper
  REPORT_TABLE = 'test_management_cucumber_report'

  def self.bucket(project)
    ApplicationHelper.report_params(project)['bucket']
  end


  def self.get_all_reports(project)
    cut_time = (Date.tomorrow - ApplicationHelper.report_params(project)['days_to_keep']).to_time.to_i
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['update_time'] = {comparison_operator: 'GE', attribute_value_list: [cut_time]}
    ApplicationHelper.dynamodb_get_items(REPORT_TABLE, criteria)
  end

  def self.get_all_file_paths(project)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    ApplicationHelper.dynamodb_distinct_column(REPORT_TABLE, 'report_file', criteria)
  end

  def self.get_report_detail(project, report_name)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['report_file'] = {comparison_operator: 'EQ', attribute_value_list: [report_name]}
    result = ApplicationHelper.dynamodb_get_items(REPORT_TABLE, criteria)
    if result.size == 1
      result[0]
    else
      {}
    end
  end

  def self.get_report_content(project, report_name)
    dir = "#{File.dirname(__FILE__)}/../../test-reports/#{report_name}"
    puts "dir for report folder"+ dir
    File.read(dir)
    # ApplicationHelper.s3_file_read(bucket(project), report_name)
  end

  def self.keep_report?(project, date)
    return true if date==''
    date_obj = Date.strptime(date, '%m-%d-%y')
    Date.today - date_obj <= ApplicationHelper.report_params(project)['days_to_keep']
  end

  def self.update(params)
    project = params['project']
    date = params['date']
    repo = params['trigger_repo'].present? ? params['trigger_repo'] : 'N/A'
    commit = params['trigger_commit'].present? ? params['trigger_commit'] : 'N/A'
    bkt = bucket(project)
    ApplicationHelper.s3_file_list(bkt, date, 'html').each do |file|
      slash_parts = file.split('/')
      next unless slash_parts.size == 2
      at_parts = slash_parts[1].split('@')
      next unless at_parts.size == 2
      tag = at_parts[1].gsub('.html', '')
      next unless tag == params['tag']
      level = at_parts[0]
      time = ApplicationHelper.s3_file_modify_time(bkt, file).to_i
      file_content = ApplicationHelper.s3_file_read(bkt, file)
      passed = file_content.split('Passed: ')[1].split('<')[0]
      failed = file_content.split('Failed: ')[1].split('<')[0]
      record = {
          project: project,
          date: date,
          tag: tag,
          trigger_author: params['trigger_author'].strip, #the author value might have ending whitespace
          trigger_repo: repo,
          trigger_commit: commit,
          travis_url: params['travis_url'],
          passed: passed,
          failed: failed,
          update_time: time,
          s3_bucket: bkt,
          report_file: file,
          report_level: level,
          latest: 'true'
      }
      previous = get_latest_report(project, date, tag, level)
      unless previous.empty?
        previous[0]['latest']='false'
        ApplicationHelper.dynamodb_put_item(REPORT_TABLE, previous[0])
      end
      ApplicationHelper.dynamodb_put_item(REPORT_TABLE, record)
    end
  end

  def self.get_latest_report(project, date, service, level='all')
    filter = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    filter['date'] = {comparison_operator: 'EQ', attribute_value_list: [date]}
    filter['tag'] = {comparison_operator: 'EQ', attribute_value_list: [service]}
    filter['latest'] = {comparison_operator: 'EQ', attribute_value_list: ['true']}
    filter['report_level'] = {comparison_operator: 'EQ', attribute_value_list: [level]} unless level == 'all'
    ApplicationHelper.dynamodb_get_items(REPORT_TABLE, filter)
  end

  def self.notify_user(project, date, service, report_link)
    record = get_latest_report(project, date, service)
    return "There is no report for #{project}/#{date}/#{service}!" if record.size < 1
    author = record[0]['trigger_author']
    unless author.present?
      return "Report #{project}/#{date}/#{service} doesn't contain trigger_author information!"
    end
    message = "\nPlease check: <#{record[0]['travis_url']}|Travis Log>"
    place_holder = 'xxLEVELxx'
    bdd_report_link = "#{report_link}/reports/#{project}/#{date}/#{service}/#{place_holder}"
    bdd_report_link = "<#{bdd_report_link}|Test Report (#{place_holder})>"
    record.each do |r|
      link = bdd_report_link.gsub(place_holder, r['report_level'])
      message += "\n #{r['report_level']} Test: #{r['passed']} Passed | #{r['failed']} Failed. #{link}"
    end
    message += "\nTrigger Repo: #{record[0]['trigger_repo']} (#{record[0]['trigger_commit']})"
    criticals = record.select {|r| r['report_level']!='non-critical'}
    failed = criticals[0]['failed'].to_i
    #need to consider both critical and rerun, take the less failed value
    criticals.each {|c| failed = c['failed'].to_i if c['failed'].to_i < failed}
    theme = failed > 0 ? 'danger' : 'good'
    time = Time.at(record[0]['update_time']).strftime("%Y-%m-%d %H:%M:%S")
    title = failed > 0 ? "#{project} #{service} BDD Test Failed @#{time} :sob:" : "#{project} #{service} BDD Test Passed @#{time} :tada:"
    msg = SlackSender.new.send_message(theme, title, message, author)
    msg
  end

  def self.zero_if_nil(val)
    val.nil? ? '0' : val
  end

  def self.getStats(report_type)
    retVal = Hash.new()
    retVal.default = 0
    if report_type
      retVal = {
          passed: ReportsHelper.zero_if_nil(report_type['passed']),
          failed: ReportsHelper.zero_if_nil(report_type['failed'])
      }
    end
    retVal
  end

  def self.build_travis_details(details)
    # Here I am getting all the (critical or non-critical or rerun) hash that has a travis_url
    available = details.select {|_run, data| !(data['travis_url'].nil?)}
    # Here I am taking travis url in the first hash
    url = available[available.keys.first]['travis_url']
    {
        text: url.split('/').last,
        url: url
    }
  end
end