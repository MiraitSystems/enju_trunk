# -*- encoding: utf-8 -*-
require EnjuSubject::Engine.root.join('app', 'controllers', 'subjects_controller')
class SubjectsController < ApplicationController

  def search_name
    struct_subject = Struct.new(:id, :text)
    if params[:subject_id]
       # logger.error "########### if start ##########"
       a = Subject.where(id: params[:subject_id]).select("id, term").first
       result = nil
       result = struct_subject.new(a.id, a.term)
    else
      subjects = Subject.where("term like '%#{params[:search_phrase]}%'").select("id, term, term_transcription").limit(10)
      result = []
      subjects.each do |subject|
        result << struct_subject.new(subject.id, subject.term)
      end
      @test = subjects.first.try(:term_transcription)
    end
    # logger.error "########### #{result} ##########"
    # logger.error "########## #{result.inspect} ##########"
    respond_to do |format|
      format.json { render :text => result.to_json, subjects_term_transcription: @test}
    end
  end
end
