class ReportsController < ApplicationController
  include ReportsHelper
  # respond_to :html, :json
  def index
    @projects = ApplicationHelper.projects

  end

  def show
    @project = {}
    project = params[:project]
    reports = ReportsHelper.get_all_reports(project)
    out = {}
    reports.each do |report|
      date = report['date']
      tag = report['tag']
      level = report['report_level']

      out[date] ||= {}
      out[date][tag] ||= {}
      if out[date][tag][level].nil? || out[date][tag][level]['update_time'] < report['update_time']
        out[date][tag][level] = report
      end
    end
    sorted_out_keys = out.keys.sort {|a, b| Date.strptime(b, "%m-%d-%y") <=> Date.strptime(a, "%m-%d-%y")}
    sorted_out_keys.each do |k|
      @project[k] = out [k]
    end
    @project
  end

  def show_report
    file_name = "#{params[:date]}/#{params[:service]}@#{params[:type]}.html"
    file = ReportsHelper.get_report_content(params[:project], file_name)
    file.sub!('PEDMatch Cucumber Reports', "#{params[:service].upcase} BDD Reports (#{params[:type]}, #{params[:date]})")
    render :html => file.html_safe
  end

  def update
    payload = JSON.parse(request.body.read)
    ReportsHelper.update(payload)
    render json: {message: "#{payload['project']} report for #{payload['date']} is updated!"}
  end

  def notify
    response = ReportsHelper.notify_user(params[:project], params[:date], params[:service], request.base_url)
    if response.include?('ERROR:')
      render status: 400, json: {message: response}
    else
      render status: 200, json: {message: response}
    end
  end

  # def authorize
  #   if session['logged_in'] == 'yes'
  #     puts 'skipping authorize'
  #   else
  #     session['logged_in'] = 'yes'
  #     puts 'First time authorize'
  #   end
  # end
end
