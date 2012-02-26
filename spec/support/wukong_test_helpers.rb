

shared_context 'wukong', :helpers => true do
  let(:mock_record){ mock }
end


module WukongTestHelpers

  def dummy_stdio(stdin_text, &block)
    new_fhs = [StringIO.new(stdin_text), StringIO.new('', "w"), StringIO.new('', "w") ]
    old_fhs = [$stdin, $stdout, $stderr]
    begin
      $stdin, $stdout, $stderr = new_fhs
      yield
    ensure
      $stdin, $stdout, $stderr = old_fhs
    end
    [ new_fhs[1].string, new_fhs[2].string ]
  end

end
