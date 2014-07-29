class LanguagesController < InheritedResources::Base
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def update
    @language = Language.find(params[:id])
    if params[:move]
      move_position(@language, params[:move])
      return
    end
    update!
  end

  def index
    @languages = @languages.page(params[:page])
  end

  # GET /languages/search_name.json
  def search_name
    struct_language = Struct.new(:id, :text, :term_transcription)
    if params[:language_id]
      language = Language.where(id: params[:language_id]).select("id, display_name, name").first
      result = struct_language.new(language.id, language.display_name.localize)
    else
      languages = Language.where("name ilike '%#{params[:search_phrase]}%' OR display_name ilike '%#{params[:search_phrase]}%'").select("id, display_name").limit(10)
      result = []
      languages.each do |language|
        result << struct_language.new(language.id, language.display_name.localize)
      end
    end
    respond_to do |format|
      format.json { render :text => result.to_json }
    end
  end

end
