module TransitiveAuthorization
  # Records the class decorated as the authorized_user.
  class AuthorizedUser
    cattr_accessor :transitive_authorized_user
  end

  def self.included(recipient)
    # We will replace self.acts_as_authorized_user with one that
    # records the class decorated as authorized_user.
    recipient.class_eval do
      class << self
        alias_method :old_acts_as_authorized_user, :acts_as_authorized_user
      end
    end
    recipient.extend( ClassMethods )
  end
  
  module ClassMethods
    # Record the class we're decorating here.
    def acts_as_authorized_user(roles_relationship_opts = {})
      TransitiveAuthorization::AuthorizedUser.transitive_authorized_user = self
      old_acts_as_authorized_user(roles_relationship_opts)
    end

    # Macro: indicate which class authorizes this class.
    def authorized_by(authorizer)
      authorizer.to_s.camelize.constantize # get authorizer loaded
      alias_method :old_users, :users
      alias_method :old_method_missing, :method_missing
      include TransitiveAuthorization::Authorizee::InstanceMethods
      self.cattr_accessor :transitive_authorizer
      self.transitive_authorizer = authorizer
    end

    # Macro: indicates which classes this class authorizes. Takes a
    # list of classes as symbols.
    def authorizes(*authorizees)
      TransitiveAuthorization::AuthorizedUser.transitive_authorized_user.class_eval do
        alias_method :old_authorizables_for, :authorizables_for
        alias_method :old_has_role?, :has_role?
        alias_method :old_roles_for, :roles_for
        alias_method :old_method_missing, :method_missing
        include TransitiveAuthorization::Authorizer::InstanceMethods
        self.cattr_accessor :transitive_authorizees
        self.transitive_authorizees ||= Array.new
        self.transitive_authorizees << authorizees
      end
    end
  end

  module Authorizee
    module InstanceMethods
      def users
        authorizer_object = self.send(self.transitive_authorizer)
        if authorizer_object
          users = authorizer_object.send :users
          users.concat old_users
          users
        else
          old_users
        end
      end

      def method_missing(method_sym, *args)
        method_name = method_sym.to_s
        if method_name =~ /^has_(\w+)\??$/
          authorizer_object = self.send(self.transitive_authorizer)
          if authorizer_object
            if method_name =~ /\?$/
              if authorizer_object.send(method_name, *args)
                true
              else
                old_method_missing(method_sym, *args)
              end
            else
              authorizers = authorizer_object.send(method_name, *args)
              authorizers.concat old_method_missing(method_sym, *args)
              authorizers
            end
          else
            old_method_missing(method_sym, *args)
          end
        else
          old_method_missing(method_sym, *args)
        end
      end
    end
  end

  module Authorizer
    module InstanceMethods

      def authorizables_for(authorizable_class)
        result = old_authorizables_for(authorizable_class)
        if authorizable_class && authorizable_class.respond_to?(:transitive_authorizer)
          authorizers = authorizables_for(Module.const_get(authorizable_class.transitive_authorizer.to_s.camelize))
          authorizers.each do |authorizer|
            method = authorizable_class.to_s.underscore.pluralize
            result.concat authorizer.send(method)
          end
        end
        result
      end

      def has_role?(role_name, authorizable_obj=nil)
        result = false
        if authorizable_obj && authorizable_obj.respond_to?(:transitive_authorizer)
          authorizer_obj = authorizable_obj.send(authorizable_obj.transitive_authorizer)
          if authorizer_obj
            result ||= self.has_role?(role_name, authorizer_obj)
          end
        end
        result ||= old_has_role?(role_name, authorizable_obj)
        result
      end
      
      def roles_for(authorizable_obj)
        result = old_roles_for(authorizable_obj)
        if authorizable_obj && authorizable_obj.respond_to?(:transitive_authorizer)
          authorizer_obj = authorizable_obj.send(authorizable_obj.transitive_authorizer)
          if authorizer_obj
            result.concat self.roles_for(authorizer_obj)
          end
        end
        result
      end

      def has_roles_for?(authorizable_obj)
        !self.roles_for(authorizable_obj).empty?
      end

    end
  end
end
