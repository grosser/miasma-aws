require_relative "../helper"
require "miasma/contrib/aws"

# NOTE: Role has read-only rights to cfn data

describe Miasma::Models::Orchestration::Aws do
  describe "STS Assume Role", :vcr do
    before do
      @orchestration = Miasma.api(
        :type => :orchestration,
        :provider => :aws,
        :credentials => {
          :aws_access_key_id => ENV.fetch("MIASMA_AWS_ACCESS_KEY_ID", "test-key"),
          :aws_secret_access_key => ENV.fetch("MIASMA_AWS_SECRET_ACCESS_KEY", "test-secret"),
          :aws_region => ENV.fetch("MIASMA_AWS_REGION", "us-west-1"),
          :aws_sts_role_arn => ENV.fetch("MIASMA_AWS_STS_ROLE_ARN", "test-role-arn"),
        },
      )
      VCR.use_cassette("Miasma_Models_Orchestration_Global/GLOBAL_sts_initialization", :erb => true) do
        @orchestration.stacks.all
      end
    end

    it "should successfully complete read action" do
      @orchestration.stacks.all
    end

    it "should error on write action" do
      result = nil
      proc do
        begin
          @orchestration.stacks.build.save
        rescue => result
          raise result
        end
      end.must_raise Miasma::Error::ApiError
      result.response.code.must_equal 403
    end
  end

  describe "STS direct token", :vcr do
    before do
      @orchestration = Miasma.api(
        :type => :orchestration,
        :provider => :aws,
        :credentials => {
          :aws_access_key_id => ENV.fetch("MIASMA_AWS_ACCESS_KEY_ID_STS", "test-key-sts"),
          :aws_secret_access_key => ENV.fetch("MIASMA_AWS_SECRET_ACCESS_KEY_STS", "test-key-secret"),
          :aws_region => ENV.fetch("MIASMA_AWS_REGION", "us-west-1"),
          :aws_sts_token => ENV.fetch("MIASMA_AWS_STS_TOKEN", "test-role-token"),
        },
      )
      VCR.use_cassette("Miasma_Models_Orchestration_Global/GLOBAL_sts_direct_initialization") do
        @orchestration.stacks.all
      end
    end

    it "should successfully complete read action" do
      @orchestration.stacks.all
    end

    it "should error on write action" do
      result = nil
      proc do
        begin
          @orchestration.stacks.build.save
        rescue => result
          raise result
        end
      end.must_raise Miasma::Error::ApiError
      result.response.code.must_equal 403
    end
  end

  describe "MFA session token provided" do
    describe "MFA root credentials to STS assume role", :vcr do
      it "should properly assume role and access the API" do
        orchestration = Miasma.api(
          :type => :orchestration,
          :provider => :aws,
          :credentials => {
            :aws_access_key_id => ENV.fetch("MIASMA_AWS_ACCESS_KEY_ID_MFA", "test-key-mfa"),
            :aws_secret_access_key => ENV.fetch("MIASMA_AWS_SECRET_ACCESS_KEY_MFA", "test-key-mfa"),
            :aws_region => ENV.fetch("MIASMA_AWS_REGION", "us-west-1"),
            :aws_sts_session_token_code => ENV.fetch("MIASMA_AWS_STS_SESSION_TOKEN_CODE", "test-role-token"),
            :aws_sts_role_arn => ENV.fetch("MIASMA_AWS_STS_ROLE_ARN_MFA", "test-role-arn-mfa"),
          },
        )
        orchestration.stacks.all.must_be_kind_of Array
      end
    end
  end
end
