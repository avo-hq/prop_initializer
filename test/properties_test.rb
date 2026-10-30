# frozen_string_literal: true

require "test_helper"

class PropertiesTest < Minitest::Test
  def define(&block)
    Class.new do
      extend PropInitializer::Properties
      class_eval(&block)
    end
  end

  def test_keyword_props_land_in_instance_variables_and_default_to_nil
    klass = define { prop :name; prop :size }
    object = klass.new(name: "Button")

    assert_equal "Button", object.instance_variable_get(:@name)
    assert_nil object.instance_variable_get(:@size)
  end

  def test_positional_props_come_before_keywords_whatever_the_declaration_order
    klass = define { prop :name; prop :record, kind: :positional }

    assert_equal({ record: 1, name: "x" }, klass.new(1, name: "x").to_h)
    assert_equal [ [ :opt, :record ], [ :key, :name ] ], klass.instance_method(:initialize).parameters
  end

  def test_splat_double_splat_and_block_kinds
    klass = define do
      prop :first, kind: :positional
      prop :rest, kind: :*
      prop :options, kind: :**
      prop :callback, kind: :&
    end
    object = klass.new(1, 2, 3, a: 4) { :called }

    assert_equal({ first: 1, rest: [ 2, 3 ], options: { a: 4 } }, object.to_h.except(:callback))
    assert_equal :called, object.instance_variable_get(:@callback).call
  end

  def test_default_applies_when_the_argument_is_omitted_but_an_explicit_nil_stays_nil
    klass = define { prop :size, default: :md; prop :hidden, default: false }

    assert_equal({ size: :md, hidden: false }, klass.new.to_h)
    assert_equal({ size: nil, hidden: false }, klass.new(size: nil).to_h)
    assert_equal({ size: :lg, hidden: true }, klass.new(size: :lg, hidden: true).to_h)
  end

  def test_literal_defaults_survive_the_trip_through_the_generated_signature
    binary = "\xFF".b.to_sym
    klass = define do
      prop :size, default: :"with space"
      prop :offset, default: -1
      prop :tags, default: [].freeze
      prop :raw, default: binary
      prop :callback, kind: :&, default: :to_s
    end

    assert_equal({ size: :"with space", offset: -1, tags: [], raw: binary, callback: :to_s }, klass.new.to_h)
    assert_equal({ size: nil, offset: 0, tags: nil, raw: nil, callback: :to_s }, klass.new(size: nil, offset: 0, tags: nil, raw: nil).to_h)
  end

  def test_proc_default_is_called_once_per_instance
    klass = define { prop :items, default: -> { [] } }

    refute_same klass.new.to_h[:items], klass.new.to_h[:items]
  end

  def test_coercion_block_runs_on_the_instance_and_sees_earlier_props
    klass = define do
      prop :prefix
      prop :icon do |value|
        value && "#{@prefix}-#{value}".to_sym
      end
    end

    assert_equal :"tabler-home", klass.new(prefix: "tabler", icon: :home).to_h[:icon]
    assert_nil klass.new(prefix: "tabler").to_h[:icon]
  end

  def test_default_goes_through_the_coercion_block
    klass = define { prop(:icon, default: "home") { |value| value.to_sym } }

    assert_equal :home, klass.new.to_h[:icon]
  end

  def test_reader_writer_and_predicate_honor_their_visibility
    klass = define do
      prop :title, reader: :public, writer: :public, predicate: :public
      prop :secret, reader: :private, predicate: :private
    end
    object = klass.new(title: "Hi", secret: "x")

    assert_equal "Hi", object.title
    assert object.title?
    object.title = nil
    refute object.title?

    assert_raises(NoMethodError) { object.secret }
    assert_raises(NoMethodError) { object.secret? }
    assert_equal "x", object.send(:secret)
    assert object.send(:secret?)
  end

  def test_no_methods_are_generated_unless_asked_for
    klass = define { prop :name }

    refute_respond_to klass.new, :name
    refute_respond_to klass.new, :name=
    refute_respond_to klass.new, :name?
  end

  def test_after_initialize_runs_once_every_prop_is_assigned
    klass = define do
      prop :first
      prop :second, default: 2
      attr_reader :seen

      def after_initialize
        @seen = [ @first, @second ]
      end
    end

    assert_equal [ 1, 2 ], klass.new(first: 1).seen
  end

  def test_subclass_inherits_props_adds_its_own_and_can_override_a_default_without_touching_the_parent
    parent = define { prop :size, default: :md; prop :label }
    child = Class.new(parent) { prop :size, default: :lg; prop :icon }

    assert_equal({ size: :lg, label: nil, icon: :x }, child.new(icon: :x).to_h)
    assert_equal({ size: :md, label: nil }, parent.new.to_h)
    assert_raises(ArgumentError) { parent.new(icon: :x) }
  end

  def test_prop_names_that_are_ruby_keywords
    klass = define do
      prop :if, reader: :public
      prop :end, kind: :positional
      prop :class
    end
    object = klass.new(1, if: 2, class: 3)

    assert_equal({ end: 1, if: 2, class: 3 }, object.to_h)
    assert_equal 2, object.if
    assert_kind_of Class, object.class
  end

  def test_a_class_reader_is_refused_because_it_would_break_object_class
    error = assert_raises(ArgumentError) { define { prop :class, reader: :public } }

    assert_match(/`:class` property should not be defined as a reader/, error.message)
  end

  def test_prop_names_that_match_the_generated_locals
    klass = define do
      prop :property
      prop :properties
      prop :binding
      prop :if
      prop :after_initialize
      prop :value, reader: :public, writer: :public
      attr_reader :hook_ran

      def after_initialize
        @hook_ran = true
      end
    end
    object = klass.new(property: "one", properties: "many", binding: "b", if: 2, after_initialize: 3, value: "v")

    assert_equal({ property: "one", properties: "many", binding: "b", if: 2, after_initialize: 3, value: "v" }, object.to_h)
    assert object.hook_ran
    object.value = "w"
    assert_equal "w", object.value
  end

  def test_invalid_options_raise_and_print_nothing
    klass = define { }

    assert_silent do
      error = assert_raises(ArgumentError) { klass.prop :a, default: "mutable".dup }
      assert_match(/frozen object or a Proc/, error.message)

      %i[reader writer predicate].each do |option|
        error = assert_raises(ArgumentError) { klass.prop :a, option => :nope }
        assert_match(/The #{option} must be one of false, :private, :protected, :public/, error.message)
      end

      error = assert_raises(ArgumentError) { klass.prop :a, kind: :nope }
      assert_match(/The kind must be one of/, error.message)
    end
  end

  def test_declaring_props_does_not_warn_about_redefined_methods
    verbose, $VERBOSE = $VERBOSE, true
    _out, err = capture_io { define { prop :a; prop :b; prop :c, reader: :public } }

    assert_empty err
  ensure
    $VERBOSE = verbose
  end
end
