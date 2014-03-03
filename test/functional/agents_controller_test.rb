require 'test_helper'

class AgentsControllerTest < ActionController::TestCase
  fixtures :agents, :users, :agent_types, :manifestations, :carrier_types,
    :roles, :creates, :realizes, :produces, :owns, :languages, :countries,
    :agent_relationships, :agent_relationship_types

  def test_guest_should_get_index_with_query
    get :index, :query => 'Librarian1'
    assert_response :success
  end

  def test_guest_should_get_index_with_agent
    get :index, :agent_id => 1
    assert_response :success
    assert assigns(:agent)
    assert assigns(:agents)
  end

  def test_guest_should_get_index_with_resource
    get :index, :manifestation_id => 1
    assert_response :success
  end

  def test_guest_should_not_create_agent
    assert_no_difference('Agent.count') do
      post :create, :agent => { :full_name => 'test' }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_agent_myself
    sign_in users(:user1)
    assert_no_difference('Agent.count') do
      post :create, :agent => { :full_name => 'test', :user_username => users(:user1).username }
    end
    
    assert_response :success
    assigns(:agent).remove_from_index!
  end

  def test_user_should_not_create_agent_without_user_id
    sign_in users(:user1)
    assert_no_difference('Agent.count') do
      post :create, :agent => { :full_name => 'test' }
    end
    
    assert_response :forbidden
  end

  def test_user_should_not_create_other_agent
    sign_in users(:user1)
    assert_no_difference('Agent.count') do
      post :create, :agent => { :full_name => 'test', :user_id => users(:user2).username }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_create_agent
    sign_in users(:librarian1)
    assert_difference('Agent.count') do
      post :create, :agent => { :full_name => 'test' }
    end
    
    assert_redirected_to agent_url(assigns(:agent))
    assigns(:agent).remove_from_index!
  end

  # TODO: full_name以外での判断
  def test_librarian_should_create_agent_without_full_name
    sign_in users(:librarian1)
    assert_difference('Agent.count') do
      post :create, :agent => { :first_name => 'test' }
    end
    
    assert_redirected_to agent_url(assigns(:agent))
    assigns(:agent).remove_from_index!
  end

  def test_guest_should_not_show_agent_when_required_role_is_user
    get :show, :id => 5
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_guest_should_show_agent_with_work
    get :show, :id => 1, :work_id => 1
    assert_response :success
  end

  def test_guest_should_show_agent_with_expression
    get :show, :id => 1, :expression_id => 1
    assert_response :success
  end

  def test_guest_should_show_agent_with_manifestation
    get :show, :id => 1, :manifestation_id => 1
    assert_response :success
  end

  def test_user_should_show_agent
    sign_in users(:user1)
    get :show, :id => users(:user2).agent
    assert_response :success
  end

  def test_user_should_not_show_agent_when_required_role_is_librarian
    sign_in users(:user2)
    get :show, :id => users(:user1).agent
    assert_response :forbidden
  end

  def test_user_should_show_myself
    sign_in users(:user1)
    get :show, :id => users(:user1).agent
    assert_response :success
  end

  def test_librarian_should_show_agent_when_required_role_is_user
    sign_in users(:librarian1)
    get :show, :id => users(:user2).agent
    assert_response :success
  end

  def test_librarian_should_show_agent_when_required_role_is_librarian
    sign_in users(:librarian1)
    get :show, :id => users(:user1).agent
    assert_response :success
  end

  def test_librarian_should_not_show_agent_when_required_role_is_admin
    sign_in users(:librarian2)
    get :show, :id => users(:librarian1).agent
    assert_response :forbidden
  end

  def test_librarian_should_not_show_agent_not_create
    sign_in users(:librarian1)
    get :show, :id => 3, :work_id => 3
    assert_response :missing
    #assert_redirected_to new_agent_create_url(assigns(:agent), :work_id => 3)
  end

  def test_librarian_should_not_show_agent_not_realize
    sign_in users(:librarian1)
    get :show, :id => 4, :expression_id => 4
    assert_response :missing
  end

  def test_librarian_should_not_show_agent_not_produce
    sign_in users(:librarian1)
    get :show, :id => 4, :manifestation_id => 4
    assert_response :missing
    #assert_redirected_to new_agent_produce_url(assigns(:agent), :manifestation_id => 4)
  end

  def test_user_should_get_edit_myself
    sign_in users(:user1)
    get :edit, :id => users(:user1).agent
    assert_response :success
  end
  
  def test_user_should_not_get_edit_other_agent
    sign_in users(:user1)
    get :edit, :id => users(:user2).agent
    assert_response :forbidden
  end

  def test_librarian_should_edit_agent_when_required_role_is_user
    sign_in users(:librarian1)
    get :edit, :id => users(:user2).agent
    assert_response :success
  end

  def test_librarian_should_edit_agent_when_required_role_is_librarian
    sign_in users(:librarian1)
    get :edit, :id => users(:user1).agent
    assert_response :success
  end
  
  def test_librarian_should_not_get_edit_admin
    sign_in users(:librarian1)
    get :edit, :id => users(:admin).agent
    assert_response :forbidden
  end
  
  def test_guest_should_not_update_agent
    put :update, :id => 1, :agent => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_update_myself
    sign_in users(:user1)
    put :update, :id => users(:user1).agent.id, :agent => { :full_name => 'test' }
    assert_redirected_to agent_url(assigns(:agent))
    assigns(:agent).remove_from_index!
  end
  
  def test_user_should_not_update_myself_without_name
    sign_in users(:user1)
    put :update, :id => users(:user1).agent.id, :agent => { :first_name => '', :last_name => '', :full_name => '' }
    assert_response :success
  end
  
  def test_user_should_not_update_other_agent
    sign_in users(:user1)
    put :update, :id => users(:user2).agent.id, :agent => { :full_name => 'test' }
    assert_response :forbidden
  end
  
  def test_librarian_should_update_other_agent
    sign_in users(:librarian1)
    put :update, :id => users(:user2).agent.id, :agent => { :full_name => 'test' }
    assert_redirected_to agent_url(assigns(:agent))
    assigns(:agent).remove_from_index!
  end
  
  def test_guest_should_not_destroy_agent
    assert_no_difference('Agent.count') do
      delete :destroy, :id => 1
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_agent
    sign_in users(:user1)
    assert_no_difference('Agent.count') do
      delete :destroy, :id => users(:user1).agent
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_agent
    sign_in users(:librarian1)
    assert_difference('Agent.count', -1) do
      delete :destroy, :id => users(:user1).agent
    end
    
    assert_redirected_to agents_url
  end

  def test_librarian_should_not_destroy_librarian
    sign_in users(:librarian1)
    assert_no_difference('Agent.count') do
      delete :destroy, :id => users(:librarian2).agent
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_destroy_librarian_who_has_items_checked_out
    sign_in users(:admin)
    assert_no_difference('Agent.count') do
      delete :destroy, :id => users(:librarian1).agent
    end
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_librarian_who_doesnt_have_items_checked_out
    sign_in users(:admin)
    assert_difference('Agent.count', -1) do
      delete :destroy, :id => users(:librarian2).agent
    end
    
    assert_redirected_to agents_url
  end
end
