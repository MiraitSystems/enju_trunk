# -*- encoding: utf-8 -*-
require EnjuSubject::Engine.root.join('app', 'models', 'subject')
class Subject < ActiveRecord::Base
  attr_accessible :term_alternative
  has_paper_trail

  def self.new_from_instance(subjects, del_subjects, add_subjects)
    editing_subjects = subjects.dup
    editing_subjects.reject!{|s| del_subjects.include?(s.id.to_s)}
    editing_subjects += self.import_subjects(add_subjects)
    editing_subjects.uniq{|s| s.id}
  end

  def self.import_subjects(subject_infos)
    transcriptions = []
    if subject_transcriptions.present?
      subject_transcriptions.uniq.compact.each do |subject_transcription|
        transcriptions += subject_transcription
      end
    end
    list = []
    subject_infos.each do |subject_info|
      unless subject_info[:id]
        if subject_info[:full_name]
          subject = Subject.add_subject(subject_info[:term], subject_info[:term_transcription])
        else
          subject = {}
        end
        subject_info[:id] = subject[:id]
      end
      if subject_info[:id]
        subject = new
        subject.id = subject_info[:id]
        lists << subject
      end
    end
    lists
  end

  def self.add_subject(term, transcription)
    return [] if term.blank?
    term = term.exstrip_with_full_size_space
    unless term.empty?
      subject = Subject.find(:first, :conditions => ["term=?", term])
      transcription = transcription.exstrip_with_full_size_space rescue nil
      if subject.nil?
        subject = Subject.new
        subject.term = term
        subject.term_transcription = transcription
        subject.save
      end
    end
    subject
  end

=begin
  def self.import_subjects(subject_lists, subject_transcriptions = nil)
    return [] if subject_lists.blank?
    subjects = subject_lists.gsub('；', ';').split(/;/)
    transcriptions = []
    if subject_transcriptions.present?
      transcriptions = subject_transcriptions.gsub('；', ';').split(/;/)
      transcriptions = transcriptions.uniq.compact
    end
    list = []
    subjects.compact.uniq.each_with_index do |s, i|
      s = s.to_s.exstrip_with_full_size_space
      next if s == ""
      subject = Subject.where(:term => s).first
      term_transcription = transcriptions[i].exstrip_with_full_size_space rescue nil
      unless subject
        # TODO: Subject typeの設定
        subject = Subject.new(
          :term => s,
          :term_transcription => term_transcription,
          :subject_type_id => 1,
        )
        subject.required_role = Role.where(:name => 'Guest').first
        subject.save
      else
        if term_transcription
          subject.term_transcription = term_transcription
          subject.save
        end
      end
      list << subject
    end
    list
  end
=end
end
