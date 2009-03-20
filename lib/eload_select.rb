#this is based on 
#http://dev.rubyonrails.org/ticket/5371
#and the patch 7147 
#http://dev.rubyonrails.org/attachment/ticket/7147/options_select_working_with_eager_loading.diff
#
#Enhanced to let you apply database functions to columns. These columns will be placed in the attributes of the base class
#
# ex. Contact.find :first, :include => :account, :select => 'now(), account.name, 123, "YOUR MOM" as blah'
#   returns a record where the now(), 123, and YOUR MOM is placed in contact['now()'] => "12007-07-09 blah', contact['123'] => '123', contact['blah'] => "YOUR MOM"
#   contact.account.name will return the account name
#   
#

require 'active_record/base'
require 'active_record/version'


module ActiveRecord
  module Associations
    if ActiveRecord::VERSION::STRING < '2.0.0'

    class HasManyThroughAssociation < AssociationProxy #:nodoc:
      def find(*args)
        options = Base.send(:extract_options_from_args!, args)

        conditions = "#{@finder_sql}"
        if sanitized_conditions = sanitize_sql(options[:conditions])
          conditions << " AND (#{sanitized_conditions})"
        end
        options[:conditions] = conditions

        if options[:order] && @reflection.options[:order]
          options[:order] = "#{options[:order]}, #{@reflection.options[:order]}"
        elsif @reflection.options[:order]
          options[:order] = @reflection.options[:order]
        end

        options[:from]  ||= construct_from
        options[:joins]   = construct_joins(options[:joins])
        options[:include] = @reflection.source_reflection.options[:include] if options[:include].nil?
        options[:select]||= @reflection.options[:select]||("#{@reflection.table_name}.*" unless options[:include])
        
        merge_options_from_reflection!(options)

        # Pass through args exactly as we received them.
        args << options
        @reflection.klass.find(*args)
      end
    end #HasManyThroughAssociation
    end
    
    module ClassMethods
      
      def construct_finder_sql_with_included_associations_with_eager_select(options, join_dependency)

        #call into compatible Ar-Exention plugin if loaded
        if respond_to? :construct_finder_sql_with_included_associations_with_ext
          return construct_finder_sql_with_included_associations_with_ext(options, join_dependency)
        end

        scope = scope(:find)
        sql = "SELECT "
        sql << construct_eload_select_sql((scope && scope[:select]) || options[:select], join_dependency)
	      sql << " FROM #{(scope && scope[:from]) || options[:from] || table_name} "
        sql << join_dependency.join_associations.collect{|join| join.association_join }.join


        add_joins!(sql, (ActiveRecord::VERSION::STRING < '2.0.0' ? options : options[:joins]), scope)
        add_conditions!(sql, options[:conditions], scope)
        add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        if ActiveRecord::VERSION::STRING > '2.3.0'
          add_group!(sql, options[:group], options[:having], scope)
        elsif respond_to? :add_group!
          add_group!(sql, options[:group], scope)
        else
          sql << " GROUP BY #{options[:group]} " if options[:group]
        end

        add_order!(sql, options[:order], scope)
        add_limit!(sql, options, scope) if using_limitable_reflections?(join_dependency.reflections)
        add_lock!(sql, options, scope)

        return sanitize_sql(sql)
      end

      alias_method :construct_finder_sql_with_included_associations, :construct_finder_sql_with_included_associations_with_eager_select 
      
      def columns_for_eager_loading(select_options, join_dependency) 
        additional_columns = [] 
        selected_column_map = select_options.split(',').inject({}) {|selected_column_map, column|  
          column.scan(/^\s*((\S+)\.)?(\S+)(\s+AS\s+(\S+))?\s*$/i) do  
            if ($5 || $2.nil?)  
              additional_columns << [$3, $5, column.strip] 
            else 
              selected_column_map[$2]||= [] 
              selected_column_map[$2] << $3 
            end 
          end 
          selected_column_map 
        } 
                 
        join_dependency.joins.each{|join| 
          join.column_names_with_alias(selected_column_map.delete(join.aliased_table_name) || []) 
        } 
                 
        standard_columns = column_aliases(join_dependency) 
        additional_columns.concat(selected_column_map.values) unless selected_column_map.blank? 
         
        join_dependency.join_base.additional_aliased_columns(additional_columns) 

        additional_columns << [standard_columns] unless standard_columns.blank? 
        additional_columns.collect{|column_name| column_name.last}.join(', ') 
      end 
     
      def construct_eload_select_sql(selected, join_dependency)
        select_sql = (selected && selected.strip != '*' ?  
        columns_for_eager_loading(selected, join_dependency) :  
        column_aliases(join_dependency)) 
      end 
 	
        
        
      class JoinDependency
        class JoinBase
          def additional_aliased_columns(additional_columns=[])
            additional_columns.each {|(column, alias_name, full_data)| @column_names_with_alias << [alias_name || column, alias_name || column] }
          end
          
          def column_names_with_alias(eager_loaded_columns=nil)
         
            unless @column_names_with_alias
              eager_loaded_columns =  column_names  if eager_loaded_columns.nil? || eager_loaded_columns.include?('*') 
              eager_loaded_columns = ([primary_key] + (eager_loaded_columns - [primary_key]))
              @column_names_with_alias = []
              eager_loaded_columns.each_with_index do |column_name, i|
                @column_names_with_alias << [column_name, "#{ aliased_prefix }_r#{ i }"]
              end
            end
            return @column_names_with_alias
          end 
        end#JoinBase
      end#JoinDependency
    end#ClassMethods
  end#Associations
end#ActiveRecord


    
      