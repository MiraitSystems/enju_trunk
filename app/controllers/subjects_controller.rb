# -*- encoding: utf-8 -*-
require EnjuSubject::Engine.root.join('app', 'controllers', 'subjects_controller')
class SubjectsController < ActiveRecord::Base

  def search_name
    logger.error "########## 拡張おｋ？ ##########" 
    struct_subject = Struct.new(:id, :text)
    if params[:id]
       a = Subject.where(id: params[:id]).select("id, term").first
       result = nil
       result = struct_subject.new(a.id, a.term)
    else
       subjects = Subject.where("term like '%#{params[:search_phrase]}%'").where(:id => nil).select("id, term").limit(10)
       result = []
       subjects.each do |subject|
           result << struct_subject.new(subject.id, subject.term)
       end
    end
    respond_to do |format|
      format.json { render :text => result.to_json }
    end
  end
end
