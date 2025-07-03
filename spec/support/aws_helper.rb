RSpec.configure do |config|
  config.before(:each) do
    Aws.config[:s3] = {
      stub_responses: true
    }
  end
end
