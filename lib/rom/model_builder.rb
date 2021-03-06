module ROM
  # @api private
  class ModelBuilder
    include Options

    option :name, reader: true

    attr_reader :const_name, :namespace, :klass

    def self.[](type)
      case type
      when :poro then PORO
      else
        raise ArgumentError, "#{type.inspect} is not a supported model type"
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(options = {})
      super

      if name
        parts = name.split('::')

        @const_name = parts.pop

        @namespace =
          if parts.any?
            Inflecto.constantize(parts.join('::'))
          else
            Object
          end
      end
    end

    def define_const
      namespace.const_set(const_name, klass)
    end

    def call(attrs)
      define_class(attrs)
      define_const if const_name
      @klass
    end

    class PORO < ModelBuilder
      def define_class(attrs)
        @klass = Class.new

        @klass.send(:attr_reader, *attrs)

        @klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def initialize(params)
            #{attrs.map { |name| "@#{name} = params[:#{name}]" }.join("\n")}
          end
        RUBY

        self
      end
    end
  end
end
