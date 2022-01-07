require 'active_support/concern'
require 'active_record'

module DcidevActiveRecord
  extend ActiveSupport::Concern

  included do
    scope :between_date, -> (column, start_date, end_date) {
      where("#{eval("self.#{ENV['DB']}_date_builder('#{self.table_name}.#{column}')")} BETWEEN '#{start_date}' AND '#{end_date}'")
    }

    scope :before_or_equal_to_date, -> (column, date) { 
      where("#{eval("self.#{ENV['DB']}_date_builder('#{self.table_name}.#{column}')")} <= '#{date}'") 
    }
    
    scope :after_or_equal_to_date, -> (column, date) { 
      where("#{eval("self.#{ENV['DB']}_date_builder('#{self.table_name}.#{column}')")} >= '#{date}'") 
    }
    scope :at_time, -> (column, time) { 
      where("#{eval("self.#{ENV['DB']}_time_builder('#{self.table_name}.#{column}')")} #{self.db_like_string(ENV['DB'])} '%#{time}%'") 
    }
    scope :mysql_json_contains, ->(column, key, value) {"JSON_EXTRACT(#{column}, '$.\"#{key}\"') LIKE \"%#{value}%\""}
  end

  def replace_child_from_array(new_child = [], column_name: "", child_name: "")
      new_child = new_child.to_a
      formatted = []
      existing_child = eval("self.#{child_name}")
      existing_child_values = existing_child.pluck(column_name.to_sym)
      delete_child = existing_child_values - new_child
      (existing_child_values + new_child).uniq.each do |lc|
          attr = { column_name => lc, "_destroy" => delete_child.include?(lc) }
          id = existing_child.detect { |ec| eval("ec.#{column_name} == #{lc.is_a?(String) ? "'#{lc}'" : lc}") }
          attr["id"] = id.id if id.present?
          formatted << attr
      end
      formatted
  end

  def update_by_params(params, set_nil = true)
      ActiveRecord::Base.transaction do
        self.class.column_names.each do |c|
          begin
            if set_nil
              eval("self.#{c} = params[:#{c.to_sym}]") if params.key?(c.to_sym)
              eval("self.#{c} = params['#{c}']") if params.key?(c)
            else
              eval("self.#{c} = params[:#{c.to_sym}]") if params.key?(c.to_sym) && params[c.to_sym] != nil
              eval("self.#{c} = params['#{c}']") if params.key?(c) && params[c] != nil
            end
          rescue IOError
            raise "Tidak dapat menyimpan file#{c}"
          end
        end
        params.select{|k, _| !k.is_a?(Symbol) && k.include?("_attributes")}.each do |k, _|
          eval("self.#{k} = params[:#{k.to_sym}]")
        end
        self.save
      end
    end
  

    def set_order
      return unless self.class.column_names.include?("view_order")
      if self.view_order.present?
        self.reorder
      else
        self.view_order = self.class.where.not(id: self.id).count + 1
        self.save
      end
    end

    def reorder
      return unless self.class.column_names.include?("view_order")
      return unless self.class.where(view_order: self.view_order).where.not(id: self.id).present?
      self.class.order(view_order: :asc, updated_at: :desc).each.with_index(1) do |f, i|
        f.update(view_order: i)
      end
    end

  class_methods do
    
    def new_from_params(params)
      model = self.new
      self.column_names.each do |c|
        begin
          eval("model.#{c} = params[:#{c.to_sym}]") if params.key?(c.to_sym)
          eval("model.#{c} = params['#{c}']") if params.key?(c)

        rescue IOError
          raise "Tidak dapat menyimpan file #{c}"
        end
      end
      params.select{|k, _| !k.is_a?(Symbol) && k.include?("_attributes")}.each do |k, _|
        eval("model.#{k} = params[:#{k.to_sym}]")
      end
      model
    end

    def mysql_date_builder(field)
      "DATE(CONVERT_TZ(#{field}, '+00:00', '#{Time.now.in_time_zone(Time.zone.name.to_s).formatted_offset}'))"
    end

    def mysql_time_builder(field)
      "TIME(CONVERT_TZ(#{field}, '+00:00', '#{Time.now.in_time_zone(Time.zone.name.to_s).formatted_offset}'))"
    end

    def postgresql_date_builder(field)
      "DATE(#{field}::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'::INTERVAL)"
    end

    def postgresql_time_builder(field)
      "#{field}::TIMESTAMPTZ AT TIME ZONE '#{Time.zone.now.formatted_offset}'"
    end
    
    def db_like_string(db)
      return 'ILIKE' if db == 'postgresql'
      return 'LIKE' if db == 'mysql'
    end
  end
end

ActiveRecord::Base.send(:include, DcidevActiveRecord)