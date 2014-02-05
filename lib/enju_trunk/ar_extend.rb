module EnjuTrunk
	module ArExtend
		def self.included(base)
			base.extend ClassMethods
		end

		module ClassMethods
			def find_each_with_order(options={})
				raise "need block." unless block_given?

				page = 1
				limit = options[:limit] || 10

				loop do
					offset = (page - 1) * limit
					batch = find(:all, options.merge(:limit => limit,  :offset => offset))
					page += 1

				  batch.each{|x| yield x } 
					#yield batch 

					break if batch.size < limit
				end
			end
		end
	end

end


