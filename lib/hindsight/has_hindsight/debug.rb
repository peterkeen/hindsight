# DEBUG
module Hindsight
  def self.debug(message, &block)
    @indent ||= 0
    indent = '  ' * @indent
    # puts indent + message
    @indent += 1
    block.call if block_given?
  ensure
    @indent -= 1
  end
end
