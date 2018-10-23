module UiMockHelper
  S3_DATA_BUCKET = 'ctrp-bddtest-mock-data'
  DEFAULT_LOCAL_ROOT = "#{Rails.root}/public/data_bucket"
  UI_MOCK_FOLDER = 'ui_mock'

  def self.get_search(type, action)
    puts "****Rails.env.development? #{Rails.env.development?}"
    puts action.inspect
    file_name = action=='cols' ? "search_#{type}_#{action}.json" : "search_#{type}.json"

    read_file(Rails.env.development?, file_name)
  end

  def self.get_analytic(type, chart)
    puts "****Rails.env.development? #{Rails.env.development?}"
    file_name = "analytic_#{type}_#{chart}.json"
    read_file(Rails.env.development?, file_name)
  end

  def self.get_aggregate(type, id, search)
    puts "****Rails.env.development? #{Rails.env.development?}"
    file_name = "aggregate_#{type}_#{id}_#{search}.json"
    read_file(Rails.env.development?, file_name)
  end

  def self.get_query(type, id)
    puts "****Rails.env.development? #{Rails.env.development?}"
    file_name = "query_#{type}_#{id}.json"
    read_file(Rails.env.development?, file_name)
  end

  def self.read_file(is_local, file_name)
    if is_local
      puts "[UI_MOCK] checking local folder #{UI_MOCK_FOLDER}"
      begin
        result = File.read("#{DEFAULT_LOCAL_ROOT}/#{UI_MOCK_FOLDER}/#{file_name}")
      rescue => error
        puts "[UI_MOCK] ERROR when read local json file #{error.message}"
        result = nil
      end
    else
      puts "[UI_MOCK] Checking s3 folder #{S3_DATA_BUCKET}/#{UI_MOCK_FOLDER}/#{file_name}"
      begin
        result = s3_client.bucket(S3_DATA_BUCKET).object("#{UI_MOCK_FOLDER}/#{file_name}").get.body.read
      rescue => error
        puts "[UI_MOCK] ERROR when read s3 json file #{error.message}"
        result = nil
      end
    end
    result
  end


  def self.s3_client
    @s3 ||= Aws::S3::Resource.new(region: 'us-east-1')
  end

end