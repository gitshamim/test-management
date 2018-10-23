class UiMockServiceController < ApplicationController
  include UiMockHelper

  def show_search
    render json: UiMockHelper.get_search(params[:type], params['action'])
  end

  def show_analytic
    render json: UiMockHelper.get_analytic(params[:type], params['chart'])
  end

  def show_aggregate
    render json: UiMockHelper.get_aggregate(params[:type], params[:id], params[:search])
  end

  def show_query
    render json: UiMockHelper.get_query(params[:type], params[:id])
  end
end