# spec/support/env_helper.rb
module EnvHelper
  def with_aws_env(&block)
    ClimateControl.modify AWS_REGION: 'us-east-1', AWS_BUCKET: 'test-bucket', &block
  end
end
