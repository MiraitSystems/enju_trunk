Rails.application.routes.draw do

  devise_scope :user do
    match '/opac' => 'opac#index'
  end

  devise_for :users, path: 'accounts'
end
