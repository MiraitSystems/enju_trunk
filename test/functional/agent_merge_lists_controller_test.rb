require 'test_helper'

class AgentMergeListsControllerTest < ActionController::TestCase
  fixtures :agent_merge_lists, :users

  def test_guest_should_not_create_agent_merge_list
    assert_no_difference('AgentMergeList.count') do
      post :create, :agent_merge_list => { }
    end

    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_agent_merge_list
    sign_in users(:user1)
    assert_no_difference('AgentMergeList.count') do
      post :create, :agent_merge_list => { }
    end

    assert_response :forbidden
  end

  def test_librarian_should_not_create_agent_merge_list_without_title
    sign_in users(:librarian1)
    assert_no_difference('AgentMergeList.count') do
      post :create, :agent_merge_list => { }
    end

    assert_response :success
  end

  def test_librarian_should_create_agent_merge_list
    sign_in users(:librarian1)
    assert_difference('AgentMergeList.count') do
      post :create, :agent_merge_list => {:title => 'test'}
    end

    assert_redirected_to agent_merge_list_url(assigns(:agent_merge_list))
  end

  def test_guest_should_not_show_agent_merge_list
    get :show, :id => agent_merge_lists(:agent_merge_list_00001).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_agent_merge_list
    sign_in users(:user1)
    get :show, :id => agent_merge_lists(:agent_merge_list_00001).id
    assert_response :forbidden
  end

  def test_librarian_should_show_agent_merge_list
    sign_in users(:librarian1)
    get :show, :id => agent_merge_lists(:agent_merge_list_00001).id
    assert_response :success
  end

  def test_guest_should_not_update_agent_merge_list
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :agent_merge_list => { }
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_update_agent_merge_list
    sign_in users(:user1)
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :agent_merge_list => { }
    assert_response :forbidden
  end

  def test_librarian_should_not_update_agent_merge_list_without_title
    sign_in users(:librarian1)
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :agent_merge_list => {:title => ""}
    assert_response :success
  end

  def test_librarian_should_update_agent_merge_list
    sign_in users(:librarian1)
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :agent_merge_list => { }
    assert_redirected_to agent_merge_list_url(assigns(:agent_merge_list))
  end

  def test_librarian_should_not_merge_agents_without_selected_agent_id
    sign_in users(:librarian1)
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :mode => 'merge'

    assert_equal I18n.t('merge_list.specify_id', :model => I18n.t('activerecord.models.agent')), flash[:notice]
    assert_redirected_to agent_merge_list_url(assigns(:agent_merge_list))
  end

  def test_librarian_should_merge_agents_with_selected_agent_id_and_merge_mode
    sign_in users(:librarian1)
    put :update, :id => agent_merge_lists(:agent_merge_list_00001).id, :selected_agent_id => 3, :mode => 'merge'

    assert_equal I18n.t('merge_list.successfully_merged', :model => I18n.t('activerecord.models.agent')), flash[:notice]
    assert_redirected_to agent_merge_list_url(assigns(:agent_merge_list))
  end
end
