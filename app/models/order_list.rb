class OrderList < ActiveRecord::Base
  scope :not_ordered, where(:state => 'pending')

  has_many :orders, :dependent => :destroy
  has_many :purchase_requests, :through => :orders
  belongs_to :user, :validate => true
  belongs_to :bookstore, :validate => true
  has_many :subscriptions
  before_save :set_ordered_at

  validates_presence_of :title, :user, :bookstore
  validates_associated :user, :bookstore
  validates_format_of :ordered_at_s, :with => /^\d{4}-\d{2}-\d{2}$|^\d{4}-\d{2}-\d{2} \d{2}:\d{2}/, :allow_blank => true

  attr_accessor :ordered_at_s, :edit_mode

  state_machine :initial => :pending do
    before_transition :pending => :ordered, :do => :order

    event :sm_order do
      transition :pending => :ordered
    end
  end

  paginates_per 5

  def total_price
    total = 0
    self.orders.each do |o|
      price = o.price_string_on_order.to_i rescue 0
      total = total + price
    end
    return total
  end

  def available_order?
    if self.state == "pending"
      return true
    end
    return false
  end

  def self.generate_order_list(start_at, end_at)
    # generate order list
    logger.debug "self.generate_order_list start_at=#{start_at} end_at=#{end_at}"

    order_lists = OrderList.where(:ordered_at => start_at.beginning_of_day..end_at.end_of_day)
                      .includes(:orders).order("order_lists.bookstore_id asc, orders.purchase_order_number")

    order_file_dir = File.join(Rails.root.to_s, 'private', 'system', 'order_list')
    order_file_path = File.join(order_file_dir, "order_list_#{Time.now.strftime("%s")}.tsv")
    FileUtils.mkdir_p(order_file_dir)

    CSV.open(order_file_path, "w", :col_sep => "\t") do |csv|
      csv << ["発注先","通番","発注番号","費目","書名","著者名","出版者","価格","ISBN"]
      serial_number = 0; pre_bookstore_id = -1
      order_lists.each do |order_list|
        order_list.orders.each do |o|
          if pre_bookstore_id != order_list.bookstore.id
            serial_number = 1
          end

          budget_category_group_name = ""
          if o.item.budget_category
            budget_category_group_value = budget_category_group_value(o.item.budget_category.group_id)
          end

          # ファイルへ書き込み
          row = []
          row << order_list.bookstore.name
          row << "#{serial_number}"
          row << o.purchase_order_number
          row << budget_category_group_value
          row << o.item.manifestation.original_title
          row << o.item.manifestation.creators.pluck(:full_name).first
          row << o.item.manifestation.publishers.pluck(:full_name).first
          row << o.price_string_on_order
          row << o.item.manifestation.isbn

          csv << row

          serial_number = serial_number + 1
        end
      end
    end

    return order_file_path
  end

  def self.budget_category_group_value(id)
    return Keycode.find(id).v
  end

  def order_letter_filename
    order_file_dir = File.join(Rails.root.to_s, 'private', 'system', 'order_letter', "#{self.id}")
    order_file_path = File.join(order_file_dir, "order_letter_*")
    list = Dir::glob(order_file_path)

    return (list.present?)?(list.first):(nil)
  end

  def do_order
    # generate order file
    order_file_dir = File.join(Rails.root.to_s, 'private', 'system', 'order_letter', "#{self.id}")
    order_file_path = File.join(order_file_dir, "order_letter_#{Time.now.strftime("%Y%m%d")}")
    FileUtils.mkdir_p(order_file_dir)

    self.ordered_at = Time.now

    CSV.open(order_file_path, "w", :col_sep => "\t") do |csv|
      csv << ["注文先","発注番号","ISBN","No","発注日","書名","責任表示","出版者","価格","担当","注釈","図書館名"]
      self.orders.each do |o|
        note = ""
        if o.item.note.present?
          note = o.item.note.split("\n").first
          note.chomp!
        end
        # ファイルへ書き込み
        row = []
        row << self.bookstore.name
        row << o.purchase_order_number
        row << o.item.manifestation.isbn
        row << o.item.manifestation.identifier
        row << self.ordered_at.strftime("%Y年%m月%d日")
        row << o.item.manifestation.original_title
        row << o.item.manifestation.creators.pluck(:full_name).first
        row << o.item.manifestation.publishers.pluck(:full_name).first
        row << o.price_string_on_order
        row << "大学院"
        row << note
        row << LibraryGroup.first.display_name

        csv << row
      end
    end

    # change status
    self.sm_order

  end

  def edit_mode

  end

  def order
    self.ordered_at = Time.zone.now
  end

  def ordered?
    true if self.ordered_at.present?
  end

  def set_ordered_at
    return if ordered_at_s.blank?
    begin
      self.ordered_at = Time.zone.parse("#{ordered_at_s}")
    rescue ArgumentError
    end
  end

end

# == Schema Information
#
# Table name: order_lists
#
#  id           :integer         not null, primary key
#  user_id      :integer         not null
#  bookstore_id :integer         not null
#  title        :text            not null
#  note         :text
#  ordered_at   :datetime
#  deleted_at   :datetime
#  state        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

