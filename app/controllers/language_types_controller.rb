class LanguageTypesController < InheritedResources::Base
  respond_to :html, :json
  has_scope :page, :default => 1
  load_and_authorize_resource

  def create
    create! {language_types_path}
  end

  def update
    update! {language_types_path}
  end

end
