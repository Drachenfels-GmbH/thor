class Thor
  class Argument #:nodoc:
    VALID_TYPES = [ :numeric, :hash, :array, :string ]

    attr_reader :name, :description, :enum, :required, :type, :default, :banner, :validations
    alias :human_name :name

    def initialize(name, options={})
      class_name = self.class.name.split("::").last

      type = options[:type]

      raise ArgumentError, "#{class_name} name can't be nil."                         if name.nil?
      raise ArgumentError, "Type :#{type} is not valid for #{class_name.downcase}s."  if type && !valid_type?(type)

      @name        = name.to_s
      @description = options[:desc]
      @required    = options.key?(:required) ? options[:required] : true
      @type        = (type || :string).to_sym
      @default     = options[:default]
      @banner      = options[:banner] || default_banner
      @enum        = options[:enum]
      @validations = options[:validations]

      validate! # Trigger specific validations
    end

    def usage
      required? ? banner : "[#{banner}]"
    end

    def required?
      required
    end

    def show_default?
      case default
      when Array, String, Hash
        !default.empty?
      else
        default
      end
    end

    def has_validations?
      ! @validations.nil?
    end

    def validate_value!(value)
      if has_validations?
        @validations.each_pair do |message, validation|
          validation_result = nil
          if validation.respond_to?(:call)
            validation_result = validation.call(value)
          elsif validation.respond_to?(:=~)
            validation_result = (validation =~ value)
          end
          if validation_result.nil? || (validation_result == false)
            handle_validation_error(message, value)
          end
        end
      end
    end

    def handle_validation_error(message, value) #:nodoc:
      msg = "Validation failed for argument value: \n"
      msg << "  Argument: #{name}\n"
      msg << "  Value: #{value}\n"
      msg << "  Error: #{message}\n"
      msg << "  Usage: #{usage} # #{description}\n"
      raise InvocationError, msg
    end

    protected

      def validate!
        if required? && !default.nil?
          raise ArgumentError, "An argument cannot be required and have default value."
        elsif @enum && !@enum.is_a?(Array)
          raise ArgumentError, "An argument cannot have an enum other than an array."
        end
      end

      def valid_type?(type)
        self.class::VALID_TYPES.include?(type.to_sym)
      end

      def default_banner
        case type
        when :boolean
          nil
        when :string, :default
          human_name.upcase
        when :numeric
          "N"
        when :hash
          "key:value"
        when :array
          "one two three"
        end
      end

  end
end
