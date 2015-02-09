class CreateTypes < ActiveRecord::Migration
  def change
    create_type 'tls_version', %w(
      SSLv30
      TLSv10
      TLSv11
      TLSv12
    )
  
    create_type 'tls_cipher_suite', YAML.load_file(Rails.root.join "config/cipher_suites.yml").values
  end

  protected

  def create_type(name, values)
    execute "CREATE TYPE #{name} AS ENUM (" << values.map{|v| "'#{v}'" }.join(",") << ")"
  end
end
