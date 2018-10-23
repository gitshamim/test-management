require 'aws-sdk'
require 'tempfile'
require 'json'
require 'active_record'

module ApplicationHelper

  def self.project_config
    #file = s3_file_read('nci-test-management', 'projects.json')
    current_dir = File.dirname(__FILE__)
    @file_dir = "#{current_dir}/../test_management/"
    puts @file_dir
    # file_path =
    file = read_json_from_dir "#{@file_dir}", "projects"
    puts "project file: #{file}"
    # @project ||= JSON.parse(file)
    @project ||= file
  end

  def self.projects
    project_config.keys
  end

  def self.report_params(project)
    project_config[project]['report']
  end

  def self.s3_client
    @s3_client ||= Aws::S3::Resource.new(
        endpoint: 'https://s3.amazonaws.com',
        region: 'us-east-1',
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def self.s3_file_list(bucket, path, extension='')
    objects = s3_client.bucket(bucket).objects(prefix: path)
    if extension.present?
      objects = objects.select {|s3_object|
        s3_object.key.end_with?(".#{extension}")}
    end
    objects.collect(&:key)
  end

  def self.s3_file_read(bucket, file_path)
    s3_client.bucket(bucket).object(file_path).get.body.read
  end

  def self.s3_file_modify_time(bucket, file_path)
    s3_client.bucket(bucket).object(file_path).last_modified.getlocal
  end

  def self.s3_upload_string(bucket, string, aws_file)
    s3_client.bucket(bucket).object(aws_file).put(body: string)
  end

  def self.dynamodb_client
    @dynamodb_client ||= Aws::DynamoDB::Client.new(
        endpoint: 'http://localhost:8000',
        region: 'us-east-1',
        # access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        # secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
    @dynamodb_client
  end

  def self.dynamodb_put_item(table_name, item_hash)
    dynamodb_client.put_item({:item => item_hash, :table_name => table_name})
  end

  def self.dynamodb_get_items(table, criteria={}, columns=[])
    # filter = {}
    # criteria.map {|k, v| filter[k] = {comparison_operator: 'EQ', attribute_value_list: [v]}}
    filter = criteria
    scan_option = {table_name: table}
    scan_option['scan_filter'] = filter unless filter.empty?
    scan_option['conditional_operator'] = 'AND' if filter.length>1
    scan_option['attributes_to_get'] = columns unless columns.empty?
    dynamodb_scan_all(scan_option)
  end

  def self.dynamodb_scan_all(opt, start_key={})
    return {} if start_key.nil?
    if start_key.size > 0
      opt['exclusive_start_key'] = start_key
    end
    scan_result = dynamodb_client.scan(opt)
    items = scan_result.items
    items.push(*dynamodb_scan_all(opt, scan_result.last_evaluated_key))
  end

  def self.dynamodb_distinct_column(table, distinct_column, criteria={})
    all_result = dynamodb_get_items(table, criteria)
    all_result.map {|hash| hash[distinct_column]}.uniq
  end

  def self.ecs_live_image_names(service_name)
    client = Aws::ECS::Client.new(
        region: 'us-east-1',
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
    resp = client.describe_task_definition({task_definition: service_name})
    container = resp.to_h[:task_definition][:container_definitions]
    if container.size < 1
      %w(No image in this container)
    else
      container.collect {|c| c[:image]}
    end
  end

  # def self.upload_report
  #   hash = JSON.parse(File.read('/Users/wangl17/Downloads/test_reporter_cache_ctrp.txt'))
  #   hash.each do |file, v|
  #     puts "processing #{file}"
  #     date = file.split('/')[0]
  #     tag = file.split('/')[1].split('@')[1].gsub('.html', '')
  #     level = file.split('/')[1].split('@')[0]
  #     begin
  #       time = ApplicationHelper.s3_file_modify_time('ctrp-test-reports', file).to_i
  #     rescue
  #       puts "!!!!!!!file #{file} doesn't exist!"
  #       next
  #     end
  #     passed = v['passed'].to_s
  #     failed = v['failed'].to_s
  #     record = {
  #         project: 'ctrp',
  #         date: date,
  #         tag: tag,
  #         passed: passed,
  #         failed: failed,
  #         update_time: time,
  #         s3_bucket: 'ctrp-test-reports',
  #         report_file: file,
  #         report_level: level
  #     }
  #     ApplicationHelper.dynamodb_put_item('test_management_cucumber_report', record)
  #   end
  # end

  def self.read_json_from_dir(dir, json_file_name)
    data_directory = dir
    json_path = "#{data_directory}/#{json_file_name}.json"
    rd_json = File.read(json_path)
    json_data = JSON.load(rd_json) #, :quirks_mode => true)
    # puts json_data
    # json_data_hash = JSON.parse(json_data)
    # return json_data_hash
  end


end

