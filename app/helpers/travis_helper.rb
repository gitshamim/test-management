require 'aws-sdk'
require 'tempfile'
require 'json'
require 'active_record'
module TravisHelper
  TRIGGER_TABLE = 'test_management_dynamic_tags'
  NEW_CYCLE = 'NOT_YET'

  def self.get_tags(project, cuc_tag)
    trigger_tag = process_tag(cuc_tag)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['trigger_cuc_tag'] = {comparison_operator: 'EQ', attribute_value_list: [trigger_tag]}
    criteria['deploy_time'] = {comparison_operator: 'EQ', attribute_value_list: [NEW_CYCLE]}
    result = ApplicationHelper.dynamodb_get_items(TRIGGER_TABLE, criteria)
    if result.size > 0
      response = result[0]['dynamic_tags'].join(',')
      if response.length == 0
        response = "ERROR: dynamic tags has been cleared for CUC_TAG #{cuc_tag}, please setup the tags firstly!"
      end
      response
    else
      trigger_tag
    end
  end

  def self.set_tags(project, cuc_tag, tag_array)
    tags = tag_array.map {|t| process_tag(t)}
    item = {
        trigger_cuc_tag: process_tag(cuc_tag),
        dynamic_tags: tags,
        project: project,
        deploy_time: NEW_CYCLE
    }
    ApplicationHelper.dynamodb_put_item(TRIGGER_TABLE, item)
  end

  def self.deploy_tags(project, cuc_tag, deployed_image)
    trigger_tag = process_tag(cuc_tag)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['trigger_cuc_tag'] = {comparison_operator: 'EQ', attribute_value_list: [trigger_tag]}
    criteria['deploy_time'] = {comparison_operator: 'EQ', attribute_value_list: [NEW_CYCLE]}
    result = ApplicationHelper.dynamodb_get_items(TRIGGER_TABLE, criteria)
    if result.size > 0
      item = result[0]
    else
      item = {
          trigger_cuc_tag: trigger_tag,
          dynamic_tags: [trigger_tag],
          project: project
      }
    end
    item['deploy_time'] = DateTime.now.in_time_zone('America/New_York').to_s
    item['deployed_image'] = deployed_image
    ApplicationHelper.dynamodb_put_item(TRIGGER_TABLE, item)
  end

  def self.tags_history(project, cuc_tag)
    trigger_tag = process_tag(cuc_tag)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    criteria['trigger_cuc_tag'] = {comparison_operator: 'EQ', attribute_value_list: [trigger_tag]}
    ApplicationHelper.dynamodb_get_items(TRIGGER_TABLE, criteria)
  end

  def self.trigger_tags(project)
    criteria = {project: {comparison_operator: 'EQ', attribute_value_list: [project]}}
    ApplicationHelper.dynamodb_get_items(TRIGGER_TABLE, criteria).collect {|t| t['trigger_cuc_tag']}.uniq
  end

  def self.process_tag(tag)
    tag.start_with?('@') ? tag : "@#{tag}"
  end
end