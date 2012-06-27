shared_context 'widgets', :helpers => true do
  let(:sample_dataflow){ Wukong.dataflow(:sample) }
  let(:next_stage){ mock('next stage') }

  def mock_next_stage(obj=nil)
    (obj ||= subject).set_output next_stage
  end
end

shared_examples_for 'a processor' do

  it{ should respond_to(:process) }
  it{ should respond_to(:setup) }
  it{ should respond_to(:stop) }
  it{ should respond_to(:report) }
  its(:report){ should be_a(Hash) }
end

shared_examples_for "a filter processor" do |objects|
  it_behaves_like 'a processor'

  it 'accepts good objects' do
    objects[:good].each do |obj|
      subject.select?(obj).should be_true
      subject.reject?(obj).should be_false
    end
  end unless objects[:good].empty?

  it 'rejects bad objects' do
    objects[:bad].each do |obj|
      subject.select?(obj).should be_false
      subject.reject?(obj).should be_true
    end
  end unless objects[:bad].empty?

  context '#process' do
    before{ mock_next_stage }

    objects[:good].each do |obj|
      it "passes along objects like #{obj.inspect}" do
        next_stage.should_receive(:process).with(obj)
        subject.process(obj)
      end
    end unless objects[:good].empty?
    objects[:bad].each do |obj|
      it "drops objects like #{obj.inspect}" do
        next_stage.should_not_receive(:process)
        subject.process(obj)
      end
    end unless objects[:bad].empty?

    it "passes along good objects if select? is true" do
      subject.stub(:select?).and_return(true)
      subject.stub(:reject?).and_return(false)
      next_stage.should_receive(:process).with(mock_record)
      subject.process(mock_record)
    end
    it "drops objects if reject? is true" do
      subject.stub(:select?).and_return(false)
      subject.stub(:reject?).and_return(true)
      next_stage.should_not_receive(:process)
      subject.process(mock_record)
    end
  end
end
