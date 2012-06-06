class BadRecord
  include Gorillib::Model
  field :contents, Whatever,  :doc => "The faulty contents; will be truncated at 1000 characters"
  field :error,    Exception, :doc => "Error (optional)"

  def receive_contents(contents)
    super contents.to_s[0..1000]
  end

  def make(contents, error=nil)
    hsh = { :contents => contents }
    hsh[:error] = error if error
    receive(hsh)
  end
end
