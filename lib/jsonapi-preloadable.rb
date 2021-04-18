module Preloadable
  def self.included(base)
    base.extend(ClassMethods)
  end

  class PreloadableAttributeConfig
    attr_writer :attrs, :defaults

    def attrs
      @attrs ||= {}
    end

    def defaults
      @defaults ||= Set.new
    end

    def add(*args)
      if args.size == 1
        # plain declaration
        # config.add relationship: :nested
        options = args.first
        attrs[options.keys.first] = options
      else
        # aliased declaration
        # config.add :alias, relationship: :nested
        key, value = args
        attrs[key] = value
      end
    end

    def preload(*keys)
      keys = [keys] if keys.instance_of?(Symbol)
      defaults.merge(keys)
    end
  end

  module ClassMethods
    def preloadable_config
      @preloadable_config ||= PreloadableAttributeConfig.new
    end

    def preloadable(&block)
      block.call(preloadable_config)
    end

    def records(options = {})
      attrs = preloadable_config.defaults.dup

      context_args = options.dig(:context, :preload)
      if context_args.present?
        attrs.merge(context_args.split(",").map(&:to_sym))
      end

      return super if attrs.empty?

      includable = preloadable_config.attrs.map do |key, value|
        value if attrs.include?(key)
      end.compact

      super.includes(includable)
    end
  end
end
