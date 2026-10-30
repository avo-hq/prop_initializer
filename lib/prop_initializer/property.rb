# frozen_string_literal: true

class PropInitializer::Property
  ORDER = { :positional => 0, :* => 1, :keyword => 2, :** => 3, :& => 4 }.freeze
  RUBY_KEYWORDS = %i[alias and begin break case class def do else elsif end ensure false for if in module next nil not or redo rescue retry return self super then true undef unless until when while yield].to_h { |k| [ k, "__#{k}__" ] }.freeze
  GENERATOR_PROPERTY_LOCAL = "__pi_prop"

  VISIBILITY_OPTIONS = Set[false, :private, :protected, :public].freeze
  KIND_OPTIONS = Set[:positional, :*, :keyword, :**, :&].freeze

  include Comparable

  def initialize(name:, kind:, reader:, writer:, predicate:, default:, coercion:)
    @name = name
    @kind = kind
    @reader = reader
    @writer = writer
    @predicate = predicate
    @default = default
    @coercion = coercion
  end

  attr_reader :name, :kind, :reader, :writer, :predicate, :default, :coercion

  def optional?
    default?
  end

  def required?
    !optional?
  end

  def keyword?
    @kind == :keyword
  end

  def positional?
    @kind == :positional
  end

  def splat?
    @kind == :*
  end

  def double_splat?
    @kind == :**
  end

  def block?
    @kind == :&
  end

  def default?
    nil != @default
  end

  # Symbol, Integer, true and false go into the signature as literals, so the initializer never looks the
  # property up. Not for a block parameter, and not for a Symbol the generated UTF-8 source cannot spell.
  def inline_default?
    return false unless positional? || keyword?

    Integer === @default || true == @default || false == @default ||
      (Symbol === @default && (Encoding::UTF_8 == @default.encoding || Encoding::US_ASCII == @default.encoding))
  end

  def lookup?
    (default? && !inline_default?) || !!@coercion
  end

  def param
    case @kind
    when :*
      "*#{escaped_name}"
    when :**
      "**#{escaped_name}"
    when :&
      "&#{escaped_name}"
    when :positional
      escaped_name
    when :keyword
      "#{@name.name}:"
    else
      raise "You should never see this error."
    end
  end

  def <=>(other)
    ORDER[@kind] <=> ORDER[other.kind]
  end

  def ruby_keyword?
    !!RUBY_KEYWORDS[@name]
  end

  def escaped_name
    RUBY_KEYWORDS[@name] || @name.name
  end

  def generate_reader_method(buffer = +"")
    buffer << @reader.name << " attr_reader :" << @name.name << "\n"
  end

  def generate_writer_method(buffer = +"")
    return buffer << @writer.name << " attr_writer :" << @name.name << "\n" unless @coercion

    buffer <<
      @writer.name << " def " << @name.name << "=(value)\n" \
      "  @" << @name.name << " = instance_exec(value, &self.class.prop_initializer_properties[:" << @name.name << "].coercion)\n" \
      "end\n"
  end

  def generate_predicate_method(buffer = +"")
    buffer <<
      (@predicate ? @predicate.name : "public") <<
      " def " <<
      @name.name <<
      "?\n" <<
      "  !!@" <<
      @name.name <<
      "\n" <<
      "end\n"
  end

  def generate_initializer_handle_property(buffer = +"")
    buffer << "  # " << @name.name << "\n"

    if lookup?
      buffer << "  #{GENERATOR_PROPERTY_LOCAL} = __pi_properties[:" << @name.name << "]\n"
    end

    if @kind == :keyword && ruby_keyword?
      generate_initializer_escape_keyword(buffer)
    end

    if default? && !inline_default?
      generate_initializer_assign_default(buffer)
    end

    if @coercion
      generate_initializer_coerce_property(buffer)
    end

    generate_initializer_assign_value(buffer)
  end

  private

  def generate_initializer_escape_keyword(buffer = +"")
    buffer <<
      escaped_name <<
      " = ::Kernel.binding.local_variable_get(:" <<
      @name.name <<
      ")\n"
  end

  def generate_initializer_coerce_property(buffer = +"")
    buffer <<
      "  " <<
      escaped_name <<
      " = instance_exec(" <<
      escaped_name <<
      ", &#{GENERATOR_PROPERTY_LOCAL}.coercion)\n"
  end

  def generate_initializer_assign_default(buffer = +"")
    buffer <<
      "  if " <<
      ((@kind == :&) ? "nil" : "PropInitializer::Null") <<
      " == " <<
      escaped_name <<
      "\n    " <<
      escaped_name <<
      " = " << (Proc === @default ? "instance_exec(&#{GENERATOR_PROPERTY_LOCAL}.default)" : "#{GENERATOR_PROPERTY_LOCAL}.default") << "\n  end\n"
  end

  def generate_initializer_assign_value(buffer = +"")
    buffer <<
      "  @" <<
      @name.name <<
      " = " <<
      escaped_name <<
      "\n"
  end
end
