shared_context 'widgets', :helpers => true do
  let(:sample_dataflow){ Wukong.dataflow(:sample) }
  let(:next_stage){ mock('next stage') }

  def mock_next_stage(obj=nil)
    (obj ||= subject).set_sink next_stage
  end
end

shared_examples_for "a filter processor" do |options|
  name = options[:named]
  if name
    it_behaves_like 'a processor', :named => name

    goods = (options[:good] || [])
    it 'accepts good objects' do
      proc  = processor(name)
      goods.each { |good| proc.given(good) }
      proc.should emit(*goods)
    end unless goods.empty?

    bads = (options[:bad] || [])
    it 'accepts bad objects' do
      proc  = processor(name)
      bads.each { |bad| proc.given(bad) }
      proc.should emit(0).records
    end unless bads.empty?
    
  else
    warn "Must supply a name for the filter processor you want to test"
  end
end
