module PropInitializer::Properties
  def prop(name, kind: :keyword, reader: false, writer: false, predicate: false, default: nil, &coercion)
    if default && !(Proc === default || default.frozen?)
      raise ArgumentError.new("The default must be a frozen object or a Proc.")
    end

    unless PropInitializer::Property::VISIBILITY_OPTIONS.include?(reader)
      raise ArgumentError.new("The reader must be one of #{PropInitializer::Property::VISIBILITY_OPTIONS.map(&:inspect).join(', ')}.")
    end

    unless PropInitializer::Property::VISIBILITY_OPTIONS.include?(writer)
      raise ArgumentError.new("The writer must be one of #{PropInitializer::Property::VISIBILITY_OPTIONS.map(&:inspect).join(', ')}.")
    end

    unless PropInitializer::Property::VISIBILITY_OPTIONS.include?(predicate)
        raise ArgumentError.new(p"The predicate must be one of #{PropInitializer::Property::VISIBILITY_OPTIONS.map(&:inspect).join(', ')}.")
    end

    if reader && :class == name
      raise ArgumentError.new(
        "The `:class` property should not be defined as a reader because it breaks Ruby's `Object#class` method, which PropInitializer itself depends on.",
      )
    end

    unless PropInitializer::Property::KIND_OPTIONS.include?(kind)
      raise ArgumentError.new("The kind must be one of #{PropInitializer::Property::KIND_OPTIONS.map(&:inspect).join(', ')}.")
    end

    property = __prop__initializer_property_class__.new(
      name:,
      kind:,
      reader:,
      writer:,
      predicate:,
      default:,
      coercion:,
    )

    prop_initializer_properties << property
    __define_prop_initializer_methods__(property)
    include(__prop__initializer_extension__)
  end

  def prop_initializer_properties
    return @prop_initializer_properties if defined?(@prop_initializer_properties)

    if superclass.is_a?(PropInitializer::Properties)
      @prop_initializer_properties = superclass.prop_initializer_properties.dup
    else
      @prop_initializer_properties = PropInitializer::Properties::Schema.new
    end
  end

  private

  def __prop__initializer_property_class__
    PropInitializer::Property
  end

  def __define_prop_initializer_methods__(new_property)
    __prop__initializer_extension__.module_eval(
      __generate_prop_initializer_methods__(new_property),
    )
  end

  def __prop__initializer_extension__
    if defined?(@__prop__initializer_extension__)
      @__prop__initializer_extension__
    else
      @__prop__initializer_extension__ = Module.new
    end
  end

  def __generate_prop_initializer_methods__(new_property, buffer = +"")
    buffer << "# frozen_string_literal: true\n"
    prop_initializer_properties.generate_initializer(buffer)
    prop_initializer_properties.generate_to_h(buffer)
    new_property.generate_writer_method(buffer) if new_property.writer
    new_property.generate_reader_method(buffer) if new_property.reader
    new_property.generate_predicate_method(buffer) if new_property.predicate
    buffer
  end
end
