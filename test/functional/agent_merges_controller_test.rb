require 'test_helper'

class AgentMergesControllerTest < ActionController::TestCase
    fixtures :agent_merges, :agents, :agent_merge_lists, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_equal assigns(:agent_merges), []
  end

  def test_user_should_not_get_index
    sign_in users(:user1)
    get :index
    assert_response :forbidden
    assert_equal assigns(:agent_merges), []
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert_not_nil assigns(:agent_merges)
  end

  def test_librarian_should_get_index_with_agent_id
    sign_in users(:librarian1)
    get :index, :agent_id => 1
    assert_response :success
    assert assigns(:agent)
    assert_not_nil assigns(:agent_merges)
  end

  def test_librarian_should_get_index_with_agent_merge_list_id
    sign_in users(:librarian1)
    get :index, :agent_merge_list_id => 1
    assert_response :success
    assert assigns(:agent_merge_list)
    assert_not_nil assigns(:agent_merges)
  end

  def test_guest_should_not_get_new
    get :new
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_new
    sign_in users(:user1)
    get :new
    assert_response :forbidden
  end

  def test_librarian_should_get_new
    sign_in users(:librarian1)
    get :new
    assert_response :success
  end

  def test_guest_should_not_create_agent_merge
    assert_no_difference('AgentMerge.count') do
      post :create, :agent_merge => { }
    end

    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_agent_merge
    sign_in users(:user1)
    assert_no_difference('AgentMerge.count') do
      post :create, :agent_merge => { }
    end

    assert_response :forbidden
  end

  def test_librarian_should_create_agent_merge_without_agent_id
    sign_in users(:librarian1)
    assert_no_difference('AgentMerge.count') do
      post :create, :agent_merge => {:agent_merge_list_id => 1}
    end

    assert_response :success
  end

  def test_librarian_should_create_agent_merge_without_agent_merge_list_id
    sign_in users(:librarian1)
    assert_no_difference('AgentMerge.count') do
      post :create, :agent_merge => {:agent_id => 1}
    end

    assert_response :success
  end

  def test_librarian_should_create_agent_merge
    sign_in users(:librarian1)
    assert_difference('AgentMerge.count') do
      post :create, :agent_merge => {:agent_id => 1, :agent_merge_list_id => 1}
    end

    assert_redirected_to agent_merge_url(assigns(:agent_merge))
  end

  def test_guest_should_not_show_agent_merge
    get :show, :id => agent_merges(:agent_merge_00001).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_agent_merge
    sign_in users(:user1)
    get :show, :id => agent_merges(:agent_merge_00001).id
    assert_response :forbidden
  end

  def test_librarian_should_not_show_agent_merge
    sign_in users(:librarian1)
    get :show, :id => agent_merges(:agent_merge_00001).id
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => agent_merges(:agent_merge_00001).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_edit
    sign_in users(:user1)
    get :edit, :id => agent_merges(:agent_merge_00001).id
    assert_response :forbidden
  end

  def test_librarian_should_get_edit
    sign_in users(:librarian1)
    get :edit, :id => agent_merges(:agent_merge_00001).id
    assert_response :success
  end

  def test_guest_should_not_update_agent_merge
    put :update, :id => agent_merges(:agent_merge_00001).id, :agent_merge => { }
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_update_agent_merge
    sign_in users(:user1)
    put :update, :id => agent_merges(:agent_merge_00001).id, :agent_merge => { }
    assert_response :forbidden
  end

  def test_librarian_should_not_update_agent_merge_without_agent_id
    sign_in users(:librarian1)
    put :update, :id => agent_merges(:agent_merge_00001).id, :agent_merge => {:agent_id => nil}
    assert_response :success
  end

  def test_librarian_should_not_update_agent_merge_without_agent_merge_list_id
    sign_in users(:librarian1)
    put :update, :id => agent_merges(:agent_merge_00001).id, :agent_merge => {:agent_merge_list_id => nil}
    assert_response :success
  end

  def test_librarian_should_update_agent_merge
    sign_in users(:librarian1)
    put :update, :id => agent_merges(:agent_merge_00001).id, :agent_merge => { }
    assert_redirected_to agent_merge_url(assigns(:agent_merge))
  end

  def test_guest_should_not_destroy_agent_merge
    assert_no_difference('AgentMerge.count') do
      delete :destroy, :id => agent_merges(:agent_merge_00001).id
    end

    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_agent_merge
    sign_in users(:user1)
    assert_no_difference('AgentMerge.count') do
      delete :destroy, :id => agent_merges(:agent_merge_00001).id
    end

    assert_response :forbidden
  end

  def test_librarian_should_destroy_agent_merge
    sign_in users(:librarian1)
    assert_difference('AgentMerge.count', -1) do
      delete :destroy, :id => agent_merges(:agent_merge_00001).id
    end

    assert_redirected_to agent_merges_url
  end
end
