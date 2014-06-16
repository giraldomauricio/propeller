require 'rspec'
require 'propeller'
require 'webmock/rspec'

describe 'My behaviour' do

  it 'Tester should run' do
    Propeller.tester.include? 'a'
    Propeller.tester.include? 'b'
    Propeller.tester.include? 'c'
  end
end

describe 'Validate configuration' do

  it 'should read the configuration file' do
    puts "++++" + Dir.pwd
    result = Propeller.verify_params Dir.pwd + "/spec/test.yml"
    expect(result['Resources']['threads']).to eq(3)
    expect(result['Resources']['urls'].length).to eq(4)
    expect(result['Resources']['params'].length).to eq(2)
  end

  it 'should fail with no configuration file' do
      result = Propeller.run(nil)
      expect(result.to_s).to include('No arguments provided')
  end

  it 'should fail with a bad configuration file' do
    result = Propeller.run(["-f:foo"])
    expect(result.to_s).to include('Propeller requires a configuration file')
  end
end

describe 'Validate basic run' do

  it 'should run based on the configuration file' do

    stub_request(:post, "http://www.apple.com/").
        with(:body => "username=foo&password=bar").
        to_return(:status => 200, :body => "", :headers => {})

    stub_request(:post, "http://www.amazon.com/").
        with(:body => "username=foo&password=bar").
        to_return(:status => 200, :body => "", :headers => {})

    stub_request(:post, "http://www.appleadkfnodnfkd.com/").
        with(:body => "username=foo&password=bar").
        to_return(:status => 200, :body => "", :headers => {})

    stub_request(:post, "http://www.google.com/").
        with(:body => "username=foo&password=bar").
        to_return(:status => 200, :body => "", :headers => {})

    result = Propeller.run ["-f:" +Dir.pwd + "/spec/test.yml"]
    expect(result[:runs]).to be >= 10
  end

  it 'should run based on the invalid_url configuration file' do

    stub_request(:get, "http://appleadkfnodnfkd.com/").
        to_return(:status => 500, :body => "", :headers => {})

    result = Propeller.run ["-f:" +Dir.pwd + "/spec/invalid_url.yml"]
    expect(result[:runs]).to eq(1)
    expect(result[:error]).to eq(1)
  end

  it 'should run based on the valid_url configuration file' do

    stub_request(:post, "http://www.apple.com/").
        with(:body => "username=foo&password=bar").
        to_return(:status => 200, :body => "", :headers => {})

    result = Propeller.run ["-f:" + Dir.pwd + "/bin/demo.yml"]
    expect(result[:runs]).to eq(1)
    expect(result[:success]).to eq(1)
    expect(result[:fails]).to eq(0)
    expect(result[:success]).to eq(1)
    expect(result[:ok]).to eq(1)
  end

end