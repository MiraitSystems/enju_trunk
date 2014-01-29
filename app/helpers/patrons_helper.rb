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
    patron_relationship_child  = patron.children.find_by_child_id(id)
    patron_relationship_parent = patron.parents.find_by_parent_id(id)
    if patron_relationship_child
      case patron_relationship_child.patron_relationship_type_id
        when 1 # See also
          t('page.see_also')
        when 2 # Member
          t('page.member')
        when 3 # Child
          t('page.child')
      end
    elsif patron_relationship_parent
      case patron_relationship_parent.patron_relationship_type_id
        when 1 # See also
          t('page.see_also')
        when 2 # Member
          t('page.organization')
        when 3 # Child
          t('page.parent')
      end
    end
  end

  def corporate_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", corporate_types_key, Time.zone.now) rescue nil
  end

  def patron_relationship_type_facet(patron_relationship_type, current_patron_relationship_type, count = 0)
    string = ''
    current = true if current_patron_relationship_type.include?(patron_relationship_type.id.to_s)
    string << "<strong>" if current
    string << link_to("#{patron_relationship_type.display_name.localize} (" + count.to_s + ")", url_for(params.merge(:page => nil, :patron_relationship_type => (current_patron_relationship_type << patron_relationship_type.id.to_s).uniq.join(' '), :view => nil)))
    string << "</strong>" if current
    string.html_safe
  end

  def patron_type_facet(patron_type, current_patron_type, facet)
    string = ''
    current = true if current_patron_type.to_s == patron_type.name.to_s
    string << "<strong>" if current
    string << link_to("#{patron_type.display_name.localize} (" + facet.count.to_s + ")", 
      url_for(params.merge(
        :page        => nil, 
        :patron_type => patron_type.name, 
        :view        => nil)))
    string << "</strong>" if current
    string.html_safe
  end
end
