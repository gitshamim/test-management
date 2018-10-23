class VersionController < ApplicationController
  def version
    begin
      document = File.open('build_number.html', 'r')
      hash = Hash.new
      document.each_line do |line|
        str = line.to_s
        arr = str.split('=', 2)
        hash.store(arr[0], arr[1])
      end
      out = {
      :rails_version => Rails::VERSION::STRING,
      :ruby_version => RUBY_VERSION,
      :running_on => hash['Commit'].present? ? hash['Commit'].gsub!("\n",'') : '',
      :author => hash['Author'].present? ? hash['Author'].gsub!("\n",'') : '',
      :travis_build => hash['TravisBuild'].present? ? hash['TravisBuild'].gsub!("\n",'') : '',
      :travis_job => hash['TravisBuildID'].present? ? hash['TravisBuildID'].gsub!("\n",'') : '',
      :docker_instance => hash['Docker'].present? ? hash['Docker'].gsub!("\n",'') : '',
      :build_time => hash['BuildTime'].present? ? hash['BuildTime'].gsub!("\n",'') : '',
      }
      render json: out
    rescue => error
      output = {'ERROR'=>error.message}
      render json: output
    end
  end
end