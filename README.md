# PropInitializer Gem Documentation

## Overview

The `PropInitializer` gem is a flexible tool for defining properties on Ruby classes. This gem is an adaptation of the [Literal Gem](https://github.com/joeldrapper/literal), with custom modifications tailored to the needs of [Avo](https://avohq.io). We sincerely thank [Joel Drapper](https://github.com/joeldrapper) for the inspiration and base code that made this possible.

With `PropInitializer`, you can easily declare properties for any class, giving you flexible options for default values and more. However, unlike [Literal](https://github.com/joeldrapper/literal), `PropInitializer` simplifies by removing strict typing requirements, providing a more lightweight and adaptable interface.

---

## Installation

To use `PropInitializer` in your Ruby project, add the following to your Gemfile:

```ruby
gem "prop_initializer"
```

Then, run the bundle command to install it:

```bash
bundle install
```

## Usage

To start using `PropInitializer`, you need to include the module in the class where you want to define properties.

### Step 1: Extend the Properties Module

In any class, extend `PropInitializer::Properties` to enable the ability to define properties:

```ruby
class MyClass
  extend PropInitializer::Properties
end
```

### Step 2: Define Properties

Properties can be declared using the `prop` method, which generates writers and makes them available as instance variables (e.g., `@name`, `@size`, etc.).

#### Basic Syntax:

```ruby
prop :name                # A simple property, accessible via @name
prop :size, default: :md  # A property with a default value of :md
prop :args, kind: :*      # A property for handling splat arguments
prop :kwargs, kind: :**   # A property for handling keyword arguments
```

#### Custom Property with Block:

You can define a custom processing block when declaring a property, for example:

```ruby
prop :icon do |value|
  value&.to_sym       # Converts the property value to a symbol
end
```

### Step 3: Accessing Properties

By default, `PropInitializer` generates a writer for each declared property. The properties are stored as instance variables, which can be accessed within the class:

```ruby
@name    # Accesses the value of the 'name' property
@size    # Accesses the value of the 'size' property
```

#### Public Reader:

If you want to generate a public reader (getter) for a property, use the `reader: :public` option when defining the property:

```ruby
prop :title, reader: :public
```

This will automatically generate a public getter method, allowing you to retrieve the property like so:

```ruby
my_class_instance.title  # Public getter for the 'title' property
```

### Example:

```ruby
class MyComponent
  extend PropInitializer::Properties

  prop :name, reader: :public
  prop :size, default: :md, reader: :public
  prop :args, kind: :*
  prop :kwargs, kind: :**
  prop :icon do |value|
    value&.to_sym
  end
end

component = MyComponent.new(name: "Button", size: :lg)
component.name # => "Button"
component.size # => :lg
```

---

## Key Differences from [Literal](https://github.com/joeldrapper/literal)

While `PropInitializer` is based on the [Literal Gem](https://github.com/joeldrapper/literal), there are some important differences:

- **No Type Requirement:** [Literal](https://github.com/joeldrapper/literal)'s properties system enforces types, but `PropInitializer` omits this for flexibility. You can define properties without needing to specify a type.
  
- **Simplified Initializer:** The initialization process has been modified to avoid requiring types at the time of property definition.

---

## Acknowledgements

Special thanks to the team at [Literal](https://github.com/joeldrapper/literal) for their pioneering work on property-based object initialization. This gem builds upon the foundation laid by their work.

If you're looking for a more type-strict approach to property initialization, we encourage you to check out the original [Literal Gem](https://github.com/joeldrapper/literal).

--- 

Thank you for using `PropInitializer`! We hope this tool helps make your property management more efficient and adaptable in your Ruby projects.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
