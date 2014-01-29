module PatronsHelper
  include PictureFilesHelper
  def patron_custom_book_jacket(patron)
    link = ''
    patron.picture_files.each_with_index do |picture_file, i|
      if i == 0
        link += link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "patron_#{patron.id}")
      else
        link += '<span style="display: none">' + link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "patron_#{patron.id}") + '</span>'
      end
    end
    link.html_safe
  end

  def patron_relationship_anyone(patron, id)
    patron_relationship = patron.children.find_by_child_id(id)
    patron_relationship = patron.parents.find_by_parent_id(id) unless patron_relationship
    return patron_relationship
  end

  def patron_relationship_type_show(patron, id)
    pr = patron.parents.find_by_parent_id(id)
    return get_detail_name(pr.patron_relationship_type, 'p', 'c') if pr
    pr = patron.children.find_by_child_id(id)
    return get_detail_name(pr.patron_relationship_type, 'c', 'p') if pr
    return nil
  end

  def corporate_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", corporate_types_key, Time.zone.now) rescue nil
  end

  def patron_relationship_type_facet(select_id, select_relation = nil, current_type, current_relation, display_name, count)
    string = ''
    current = true if select_id == current_type && (select_relation.nil? || select_relation == current_relation)
    string << "<strong>" if current
    string << link_to("#{display_name} (" + count.to_s + ")", url_for(params.merge(:page => nil, :patron_relationship_type => select_id, :parent_child_relationship => select_relation, :view => nil)))
    string << "</strong>" if current
    string.html_safe
  end
end
