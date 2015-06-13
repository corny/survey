class MxDomain < ActiveRecord::Base
  include SelectHelper

  has_many :mx_records,
    foreign_key: :hostname,
    primary_key: :name


  def self.write_zone_file(path, options={})
    options.reverse_merge!(
      serial:   1,
      refresh:  14400,
      retry:    7200,
      expire:   604800,
      ttl:      3600
    )

    File.open(path,"w") do |f|
      f.puts "@ IN SOA master.example.com. hostmaster.example.com. ( #{options[:serial]} #{options[:refresh]} #{options[:retry]} #{options[:expire]} #{options[:ttl]} )"

      find_each do |mx_domain|
        # invalid hostname?
        next if mx_domain.name !~ /\A[a-z0-9\.\-_]+\z/

        txt = [mx_domain.txt]

        if txt[0].length > 255
          txt = txt[0].scan(/.{1,255}/)
        end

        f.puts "#{mx_domain.name} TXT " << txt.map{|t| "\"#{t}\"" }.join(" ")
      end
    end
  end

end
