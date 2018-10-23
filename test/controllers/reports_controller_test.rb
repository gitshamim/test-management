require 'test_helper'

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get reports_list_url
    assert_response :success
  end

end
