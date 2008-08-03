# setup for testing within rails
RAILS_ENV = 'test'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))

ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string 'name'
  end

  create_table :clients do |t|
    t.string 'name'
  end

  create_table :enterprises do |t|
    t.string 'name'
    t.integer 'client_id'
  end

  create_table :instances do |t|
    t.string 'name'
    t.integer 'enterprise_id'
  end

  create_table :contacts do |t|
    t.string 'name'
    t.integer 'client_id'
  end

  create_table :roles do |t|
    t.string   'name',              :limit => 40
    t.string   'authorizable_type', :limit => 40
    t.string   'authorizable_id'
  end

  create_table :roles_users, :id => false do |t|
    t.string   'user_id'
    t.integer  'role_id'
  end
end

class User < ActiveRecord::Base
  acts_as_authorizable
  acts_as_authorized_user
end

class Client < ActiveRecord::Base
  acts_as_authorizable
  has_many :enterprises
  has_many :contacts
  authorizes :enterprises, :contacts
end

class Enterprise < ActiveRecord::Base
  acts_as_authorizable
  belongs_to :client
  has_many :instances
  authorized_by :client
end

class Instance < ActiveRecord::Base
  acts_as_authorizable
  belongs_to :enterprise
  authorized_by :enterprise
end

class Contact < ActiveRecord::Base
  acts_as_authorizable
  belongs_to :client
  authorized_by :client
end
