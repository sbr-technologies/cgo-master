class OAuthSecrets
  @@providers = {
    :twitter => {:consumer_key => "HmdQtdqzPQQKrPr0sVWYw", :consumer_secret => "X9hFmlR5CrQGnUKhOcEdVMBOuCRQuiUHxdkqmUkc"},
    :linked_in   => {:consumer_key => "xuSfC_p-0MT3C_iK043h_TMmL6AtPefuVGvmkyuQzHmGUoRd4yZFsyCAgocoB_ML", :consumer_secret => "1UbG7_Y0UKJJsHekf4OlNvUW2yyhVeoFu0go-sAY23JmffUleYfAJk1EL9_e-1fO"}
  }

  def self.providers
    @@providers
  end
end
