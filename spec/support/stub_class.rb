# This helper module makes it easy to make modifications to classes for the duration of an example
# e.g. stub_class(Project) { after_save :do_something }
# At the end of the example, stubbed classes are reverted to their original behaviour
module StubClass
  mattr_accessor :original_classes
  self.original_classes = []

  def stub_class(original_class, &block)
    StubClass.original_classes << original_class
    new_class = original_class.dup
    Object.send(:remove_const, original_class.name.to_sym)
    Object.const_set(original_class.name.to_sym, new_class)
    new_class.class_eval(&block) if block_given?
    return new_class
  end

  def self.included(example_group)
    example_group.after do
      # Restore original classes
      while StubClass.original_classes.present? do
        original_class = StubClass.original_classes.pop
        Object.send(:remove_const, original_class.name.to_sym)
        Object.const_set(original_class.name.to_sym, original_class)
      end
    end
  end
end
