# frozen_string_literal: true

module Jsonapi
  module Sort
    extend ActiveSupport::Concern

    included do
      @sortable_fields ||= []
      @default_sort ||= {}
    end

    module ClassMethods
      def default_sort(sort)
        @default_sort = sort
      end

      def sortable_fields(*fields)
        @sortable_fields = fields
      end

      def apply_sort(params = {}, options = { allowed: [], default: {} })
        fields = params.dig(:sort)

        allowed_fields = (Array.wrap(options[:allowed]).presence || @sortable_fields).map(&:to_sym)
        default_order = (options[:default].presence || @default_sort).transform_keys(&:to_sym)
        ordered_fields = convert_to_ordered_hash(fields)

        ordered_fields.each do |field, _|
          raise InvalidAttributeError, "#{field} is not valid as sort attribute." unless allowed_fields.include?(field)
        end

        orders = ordered_fields.presence || default_order

        orders.each do |key, direction|
          if respond_to?(key)
            self.send(key, direction)
          elsif column_names.include?(key)
            self.order([[key, direction]].to_h)
          end
        end
      end

      private

      def convert_to_ordered_hash(fields)
        fields = fields.to_s.split(',').map(&:squish)

        fields.each_with_object({}) do |field, hash|
          if field.start_with?('-')
            field = field[1..-1]
            hash[field] = :desc
          else
            hash[field] = :asc
          end
        end.transform_keys(&:to_sym)
      end
    end
  end
end
