RSpec::Core::DSL.module_eval do
  def describe_example_script(example_name, source_file, attrs={}, &block)
    load Pathname.path_to(:examples, source_file)

    describe "Example: #{example_name}", attrs.merge(:examples_spec => true, :helpers => true) do
      subject{ ExampleUniverse.dataflow(example_name) }
      instance_eval(&block)
    end
  end
end
