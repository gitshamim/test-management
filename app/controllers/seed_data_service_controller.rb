class SeedDataServiceController < ApplicationController
  include SeedDataHelper

  def list_all_stories
    list = SeedDataHelper.all_story_ids(params[:project])
    render json: list
  end

  def list_category_stories
    list = SeedDataHelper.all_story_ids(params[:project], params[:category])
    render json: list
  end

  def list_all_categories
    list = SeedDataHelper.all_story_categories(params[:project])
    render json: list
  end

  def show_story
    story = SeedDataHelper.story(params[:story_id])
    render json: story
  end

  def create_story
    # puts 'request body is'
    # puts request.body.read
    # puts 'params is'
    # puts params.to_s
    story = {
        data_id: params[:story_id],
        project: params[:project],
        category: params[:category],
        story: JSON.parse(request.body.read)
    }
    SeedDataHelper.create(story)
    msg = "Seed story #{params[:story_id]} is created successfully!"
    render json: {message: msg}
  end

end