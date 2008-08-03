begin
  c = Module.const_get('Authorization')
rescue NameError => e
  raise "transitive_authorization needs the 'authorization' plugin loaded first"
end

require 'transitive_authorization'
ActiveRecord::Base.send(:include, TransitiveAuthorization)
