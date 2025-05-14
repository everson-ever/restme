# frozen_string_literal: true

require "pg"
require "active_record"

db_config = {
  adapter: "postgresql",
  encoding: "unicode",
  database: "restme",
  username: "postgres",
  password: "postgres",
  host: "restme_postgres",
  port: 5432
}

begin
  conn = PG.connect(
    dbname: "postgres",
    user: db_config[:username],
    password: db_config[:password],
    host: db_config[:host],
    port: db_config[:port]
  )
  result = conn.exec("SELECT 1 FROM pg_database WHERE datname='#{db_config[:database]}'")
  if result.ntuples.zero?
    conn.exec("CREATE DATABASE #{db_config[:database]}")
    puts "Banco de dados '#{db_config[:database]}' criado."
  end
  conn.close
rescue PG::Error => e
  puts "Erro ao verificar/criar o banco: #{e.message}"
  exit 1
end

ActiveRecord::Base.establish_connection(db_config)

ActiveRecord::Schema.define do
  create_table :products, force: true do |t|
    t.string :name
    t.string :code
    t.integer :establishment_id
    t.timestamps
  end
  create_table :establishments, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :users, force: true do |t|
    t.string :name
    t.string :role
    t.timestamps
  end
end

class Product < ActiveRecord::Base
  FILTERABLE_FIELDS = %i[establishment_id name created_at].freeze

  SORTABLE_FIELDS = %i[name created_at].freeze

  belongs_to :establishment
end

class Establishment < ActiveRecord::Base; end

class User < ActiveRecord::Base
  def super_admin?
    role == "super_admin"
  end
end
