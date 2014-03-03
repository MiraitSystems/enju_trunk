# encoding: utf-8
namespace :enju_trunk do
  namespace :event do
    desc '土日祝日のEventを自動で登録する'
    task :autoinsert, [:first_yyyy_mm, :last_yyyy_mm, :library_id] => :environment do |t, args|
      insert_day = Date.new(args[:first_yyyy_mm][0..3].to_i, args[:first_yyyy_mm][-2..-1].to_i, 1)
      last_day = Date.new(args[:last_yyyy_mm][0..3].to_i, args[:last_yyyy_mm][-2..-1].to_i + 1, 1)
      last_day -= 1
      while insert_day <= last_day do
        if insert_day.wday == 0 then
          @event = Event.new
          @event.library_id = args[:library_id]
          @event.event_category = EventCategory.where(:name => 'closed').first
          @event.name = "weekend"
          @event.start_at = insert_day.beginning_of_day
          @event.end_at = insert_day.end_of_day
          @event.all_day = true
          @event.display_name = "日曜日"
          @event.save
        elsif insert_day.wday == 6 then
          @event = Event.new
          @event.library_id = args[:library_id]
          @event.event_category = EventCategory.where(:name => 'closed').first
          @event.name = "weekend"
          @event.start_at = insert_day.beginning_of_day
          @event.end_at = insert_day.end_of_day
          @event.all_day = true
          @event.display_name = "土曜日"
          @event.save
        end
        insert_day += 1
      end
    end
  end
end
