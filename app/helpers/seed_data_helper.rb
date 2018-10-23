require 'aws-sdk'
require 'tempfile'
require 'json'
require 'active_record'
module SeedDataHelper
  STORY_TABLE = 'test_management_seed_story'

  def self.all_story_ids(project, category='')
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['category'] = {comparison_operator: 'EQ', attribute_value_list: [category]} if category.present?
    ApplicationHelper.dynamodb_distinct_column(STORY_TABLE, 'data_id', criteria)
  end

  def self.all_story_categories(project)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    ApplicationHelper.dynamodb_distinct_column(STORY_TABLE, 'category', criteria)
  end

  def self.story(story_id)
    filter = {data_id: {comparison_operator: 'EQ', attribute_value_list: [story_id]}}
    ApplicationHelper.dynamodb_get_items(STORY_TABLE, filter)
  end

  def self.create(story)
    ApplicationHelper.dynamodb_put_item(STORY_TABLE, story)

  end
end