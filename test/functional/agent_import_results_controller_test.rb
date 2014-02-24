require 'test_helper'

class AgentImportResultsControllerTest < ActionController::TestCase
  fixtures :agent_import_results, :users, :roles

  setup do
    @agent_import_result = agent_import_results(:one)
  end

  test "guest should not get index" do
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_equal assigns(:agent_import_results), []
  end

  test "user should not get index" do
    sign_in users(:user1)
    get :index
    assert_response :forbidden
    assert_equal assigns(:agent_import_results), []
  end

  test "librarian should not get index" do
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert_not_nil assigns(:agent_import_results)
  end

  test "guest should not show agent_import_result" do
    get :show, :id => @agent_import_result.to_param
    assert_redirected_to new_user_session_url
  end

  test "user should not show agent_import_result" do
    sign_in users(:user1)
    get :show, :id => @agent_import_result.to_param
    assert_response :forbidden
  end

  test "librarian should show agent_import_result" do
    sign_in users(:librarian1)
    get :show, :id => @agent_import_result.to_param
    assert_response :success
  end

  test "admin should not destroy agent_import_result" do
    sign_in users(:librarian1)
    assert_no_difference('AgentImportResult.count') do
      delete :destroy, :id => @agent_import_result.to_param
    end

    assert_response :forbidden
  end
end
