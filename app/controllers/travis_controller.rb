class TravisController < ApplicationController


  def check_docker_image
    live_images = ApplicationHelper.ecs_live_image_names(params[:service_name])
    msg = []
    i = 1
    live_images.each do |image|
      match = image == params[:image_to_check] ? 'match' : "doesn't match"
      m = "Live Container ##{i}: #{image} #{match} #{params[:image_to_check]}"
      msg << m
    end
    render json: msg
  end

  def set_dynamic_tags
    tags = params[:tags]
    tags << params[:cuc_tag] unless tags.include?(params[:cuc_tag])
    TravisHelper.set_tags(params[:project], params[:cuc_tag], tags)
    render json: {message: "Dynamic tags has been set for CUC_TAG #{params[:cuc_tag]}"}
  end

  def get_dynamic_tags
    response = TravisHelper.get_tags(params[:project], params[:cuc_tag])
    if response.include?('ERROR:')
      render status: 400, json: {message: response}
    else
      render status: 200, plain: response
    end
  end

  def dynamic_tags_deploy
    required_keys = %w(project cuc_tag clear_tags deployed_image)
    required_keys.each {|k|
      unless params.key?(k)
        render status: 400, json: {message: "#{required_keys.join(', ')} are required keys"} and return
      end
    }
    TravisHelper.deploy_tags(params[:project], params[:cuc_tag], params[:deployed_image])
    tags = params[:clear_tags] == 'true' ? [] : TravisHelper.get_tags(params[:project], params[:cuc_tag]).split(',')
    TravisHelper.set_tags(params[:project], params[:cuc_tag], tags)
    render json: {message: "Last set of dynamic tags for CUC_TAG #{params[:cuc_tag]} has been deployed"}
  end

  def get_dynamic_tags_history
    response = TravisHelper.tags_history(params[:project], params[:cuc_tag])
    render json: response
  end

  def get_dynamic_trigger_tags
    response = TravisHelper.trigger_tags(params[:project])
    render json: response
  end
end