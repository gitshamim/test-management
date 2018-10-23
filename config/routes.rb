Rails.application.routes.draw do
  root 'reports#index'

  # get 'reports/list'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # root 'application#index'
  controller :version do
    get 'version' => :version
  end

  controller :application do
    post 'slack_to_user/:user_name' => :slack_to_user
    post 'slack_to_channel/:channel_name' => :slack_to_channel
  end

  # resources :reports

  controller :reports do
    get '/reports', to: 'reports#index', as: 'reports'
    # get 'reports' => :index
    get 'reports/:project', to: 'reports#show', as: 'report'
    get 'reports/:project/:date/:type/:service', to: 'reports#show_report', as: 'show_report'

    get 'report_notified/:project/:date/:service', to: 'reports#notify', as: 'send_notification'
    put 'reports/update', to: 'reports#update', as: 'update_reports'

  end

  controller :travis do
    get 'docker_image_check/:service_name/:image_to_check', to: 'travis#check_docker_image', as: 'check_docker_image'
    put 'dynamic_tags/:project/:cuc_tag', to: 'travis#set_dynamic_tags', as: 'set_dynamic_tags'
    put 'dynamic_tags_deploy', to: 'travis#dynamic_tags_deploy', as: 'dynamic_tags_deploy'
    get 'dynamic_tags/:project/:cuc_tag', to: 'travis#get_dynamic_tags', as: 'get_dynamic_tags'
    get 'dynamic_tags_history/:project/:cuc_tag', to: 'travis#get_dynamic_tags_history', as: 'get_dynamic_tags_history'
    get 'dynamic_trigger_tags/:project', to: 'travis#get_dynamic_trigger_tags', as: 'get_dynamic_trigger_tags'
  end

  controller :seed_data_service do
    get 'seed_story_categories/:project' => :list_all_categories
    get 'seed_story_ids/:project' => :list_all_stories
    get 'seed_story_ids/:project/:category' => :list_category_stories
    get 'seed_story/:story_id' => :show_story
    post 'seed_story/:project/:category/:story_id' => :create_story
  end

  controller :ui_mock_service do
    get 'ui_mock/analytic/:type' => :show_analytic
    get 'ui_mock/search/:type' => :show_search
    get 'ui_mock/aggregate/:type/:id' => :show_aggregate
    get 'ui_mock/query/:type' => :show_query
  end

end
