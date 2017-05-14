module ReportsKit
  module Reports
    class Dimension
      DEFAULT_DIMENSION_INSTANCES_LIMIT = 30

      attr_accessor :properties, :measure, :configuration

      delegate :configured_by_association?, :configured_by_column?, :configured_by_model?, :configured_by_time?,
        :settings_from_model, :reflection, :instance_class, :model_class, :column_type,
        to: :configuration

      def initialize(properties, measure:)
        self.configuration = InferrableConfiguration.new(self, :dimensions)
        self.measure = measure

        raise ArgumentError.new('Blank properties') if properties.blank?
        properties = { key: properties } if properties.is_a?(String)
        raise ArgumentError.new("Measure properties must be a String or Hash, not a #{properties.class.name}: #{properties.inspect}") unless properties.is_a?(Hash)
        properties = properties.deep_symbolize_keys
        self.properties = properties
        missing_group_setting = settings && !settings.key?(:group)
        raise ArgumentError.new("Dimension settings for dimension '#{key}' of #{model_class} must include :group") if missing_group_setting
      end

      def key
        properties[:key]
      end

      def label
        key.titleize
      end

      def settings
        inferred_settings.merge(settings_from_model)
      end

      def inferred_settings
        configuration.inferred_settings.merge(inferred_dimension_settings)
      end

      def inferred_dimension_settings
        {
          group: group_expression
        }
      end

      def group_expression
        if configured_by_model?
          settings_from_model[:group]
        elsif configured_by_association?
          "#{model_class.table_name}.#{reflection.foreign_key}"
        elsif configured_by_column? && configured_by_time?
          "date_trunc('week', #{model_class.table_name}.#{key}::timestamp)"
        elsif configured_by_column?
          "#{model_class.table_name}.#{key}"
        else
          raise ArgumentError.new('Invalid group_expression')
        end
      end

      def joins
        settings_from_model[:joins] if configured_by_model?
      end

      def dimension_instances_limit
        if configured_by_time?
          properties[:limit]
        else
          properties[:limit] || DEFAULT_DIMENSION_INSTANCES_LIMIT
        end
      end

      def should_be_sorted_by_count?
        !configured_by_time?
      end
    end
  end
end
