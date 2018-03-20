# LinkedIn API Keys
# Company: Corporate Gray
# Application Name: CGO Integration
# API Key: xuSfC_p-0MT3C_iK043h_TMmL6AtPefuVGvmkyuQzHmGUoRd4yZFsyCAgocoB_ML
# Secret Key: 1UbG7_Y0UKJJsHekf4OlNvUW2yyhVeoFu0go-sAY23JmffUleYfAJk1EL9_e-1fO
#
module Social
  class LinkedIn

    @@ACCOUNT_NAME = "CorporateGray"
    @@APPLICATION_NAME = "CGO Integration"
    @@ACCESS_TOKEN = "xuSfC_p-0MT3C_iK043h_TMmL6AtPefuVGvmkyuQzHmGUoRd4yZFsyCAgocoB_ML"
    @@TOKEN_SECRET = "1UbG7_Y0UKJJsHekf4OlNvUW2yyhVeoFu0go-sAY23JmffUleYfAJk1EL9_e-1fO"

    def self.get(url, access_token=@@ACCESS_TOKEN, token_secret=@@TOKEN_SECRET)

      consumer = OAuth::Consumer.new(OAuthSecrets.providers[:linked_in][:consumer_key], OAuthSecrets.providers[:linked_in][:consumer_secret])
      handler = OAuth::AccessToken.new(consumer, access_token, token_secret) unless consumer.nil?

      if handler
        json_txt = handler.get(url, 'x-li-format' => 'json').body
      end

      return json_txt.blank? ? [] : JSON.parse(json_txt)
    end


  end
end
