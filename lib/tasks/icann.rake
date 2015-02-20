namespace :icann do
  desc "Updates the ICANN TLD list"
  task :tlds do

    res = Net::HTTP.get_response URI.parse('https://data.iana.org/TLD/tlds-alpha-by-domain.txt')
    res.error! unless res.is_a?(Net::HTTPOK)

    Rails.root.join("config/tlds.txt").open("w"){|f| f << res.body }
  end

end
