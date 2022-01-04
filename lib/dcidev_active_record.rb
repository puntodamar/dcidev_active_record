require 'active_record'

module DcidevActiveRecord
  ActiveRecord.class_eval do
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

      def test
        p "from gem"
      end
  end
end
