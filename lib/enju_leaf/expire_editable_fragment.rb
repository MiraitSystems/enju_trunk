module ExpireEditableFragment
	def expire_editable_fragment(record, fragments = [], formats = [])
		fragments.uniq!
		if record.is_a?(Manifestation)
			if fragments.empty?
				fragments = %w[detail pickup book_jacket title picture_file show_list edit_list reserve_list show_index] 
			end
			expire_manifestation_cache(record, fragments)
		else
			I18n.available_locales.each do |locale|
				Role.all_cache.each do |role|
					fragments.each do |fragment|
						expire_fragment(:controller => record.class.to_s.pluralize.downcase, :action => :show, :id => record.id, :page => fragment, :role => role.name, :locale => locale)
					end
				end
			end
		end
	end

	private
	def expire_manifestation_cache(manifestation, fragments = [])
		I18n.available_locales.each do |locale|
			Role.all_cache.each do |role|
				fragments.uniq.each do |fragment|
					expire_fragment(:controller => :manifestations, :action => :show, :id => manifestation.id, :page => fragment, :role => role.name, :locale => locale, :manifestation_id => nil)
				end
			end
		end
	end
end
