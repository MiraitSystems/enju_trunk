require 'test_helper'

class ItemsControllerTest < ActionController::TestCase
  fixtures :items, :circulation_statuses, :shelves, :orders, :manifestations,
      :carrier_types, :languages, :reserves,
      :libraries, :agents, :users, :inventories, :inventory_files,
      :user_groups, :lending_policies, :exemplifies, :library_groups

  def test_guest_should_get_index_with_agent_id
    get :index, :agent_id => 1
    assert_response :success
    assert assigns(:agent)
    assert assigns(:items)
  end

  def test_guest_should_get_index_with_manifestation_id
    get :index, :manifestation_id => 1
    assert_response :success
    assert assigns(:manifestation)
    assert assigns(:items)
  end

  def test_guest_should_get_index_with_shelf_id
    get :index, :shelf_id => 1
    assert_response :success
    assert assigns(:shelf)
    assert assigns(:items)
  end

  def test_guest_not_should_get_index_with_inventory_file_id
    get :index, :inventory_file_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert assigns(:inventory_file)
    assert_not_nil assigns(:items)
  end

  def test_user_not_should_get_index_with_inventory_file_id
    sign_in users(:user1)
    get :index, :inventory_file_id => 1
    assert_response :forbidden
  end

  def test_librarian_should_get_index_with_inventory_file_id
    sign_in users(:librarian1)
    get :index, :inventory_file_id => 1
    assert_response :success
    assert assigns(:inventory_file)
    assert assigns(:items)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  def test_everyone_should_not_get_new_without_manifestation_id
    sign_in users(:admin)
    get :new
    assert_redirected_to manifestations_url
  end
  
  def test_guest_should_not_create_item
    assert_no_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :manifestation_id => 1}
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_create_item_without_manifestation_id
    sign_in users(:admin)
    assert_no_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1 }
    end
    
    assert_response :missing
  end

  def test_everyone_should_not_create_item_already_created
    sign_in users(:admin)
    assert_no_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :item_identifier => "00001", :manifestation_id => 1}
    end
    
    assert_response :success
  end

  def test_user_should_not_create_item
    sign_in users(:user1)
    assert_no_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :manifestation_id => 1}
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_create_item
    sign_in users(:librarian1)
    old_lending_policy_count = LendingPolicy.count
    assert_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :manifestation_id => 1}
    end
    assert_equal old_lending_policy_count+UserGroup.count, LendingPolicy.count
    
    assert_redirected_to item_url(assigns(:item))
    assert assigns(:item).manifestation
    assigns(:item).remove_from_index!
  end

  def test_librarian_should_create_reserved_item
    sign_in users(:librarian1)
    assert_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :manifestation_id => 2}
    end
   
    assert_redirected_to item_url(assigns(:item))
    assert_equal flash[:message], I18n.t('item.this_item_is_reserved')
    assert assigns(:item).manifestation
    assert_equal assigns(:item).manifestation.next_reservation.state, 'retained'
    assigns(:item).remove_from_index!
  end

  def test_admin_should_create_item
    sign_in users(:admin)
    assert_difference('Item.count') do
      post :create, :item => { :circulation_status_id => 1, :manifestation_id => 1}
    end
    
    assert_redirected_to item_url(assigns(:item))
    assert assigns(:item).manifestation
    assigns(:item).remove_from_index!
  end

  def test_everyone_should_not_show_missing_item
    sign_in users(:admin)
    get :show, :id => 100
    assert_response :missing
  end

  def test_everyone_should_not_edit_missing_item
    sign_in users(:admin)
    get :edit, :id => 100
    assert_response :missing
  end

  def test_everyone_should_not_destroy_missing_item
    sign_in users(:admin)
    assert_no_difference('Item.count') do
      delete :destroy, :id => 100
    end
    
    assert_response :missing
  end

  def test_everyone_should_not_destroy_item_if_not_checked_in
    sign_in users(:admin)
    assert_no_difference('Item.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_item
    sign_in users(:librarian1)
    assert_difference('Item.count', -1) do
      delete :destroy, :id => 6
    end
    
    assert_redirected_to manifestation_items_url(assigns(:item).manifestation)
  end

  def test_admin_should_destroy_item
    sign_in users(:admin)
    assert_difference('Item.count', -1) do
      delete :destroy, :id => 6
    end
    
    assert_redirected_to manifestation_items_url(assigns(:item).manifestation)
  end
end
