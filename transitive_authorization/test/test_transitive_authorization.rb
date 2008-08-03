require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_helper_rails'

class TestTransitiveAuthorization < Test::Unit::TestCase
  
  def test_models
    u = User.new(:name => 'foo')
    assert u.save
    
    c = Client.new(:name => 'bar')
    assert c.save

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save
  end

  def test_grant_role
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)
  end

  def test_grant_role_direct_to_transitive_authorizee
    u = User.new(:name => 'foo')
    assert u.save

    e = Enterprise.new(:name => 'bar')
    assert e.save

    u.has_role 'account_manager', e
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', e)

    assert e.users.length == 1
    assert e.has_account_managers.length == 1
    assert e.has_account_managers?
  end

  def test_grant_role_direct_to_transitive_authorizee_with_authorizer
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    u.has_role 'account_manager', e
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', e)

    assert e.users.length == 1
    assert e.has_account_managers.length == 1
    assert e.has_account_managers?
  end

  def test_transitive_from_authorizable
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save
    assert e.users.length == 1
    assert e.has_account_managers.length == 1
    assert e.has_account_managers?
  end
  
  def test_transitive_from_authorizer_has_role?
    u = User.new(:name => 'foo')
    assert u.save
    
    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save
    assert e.users.length == 1
    assert u.has_role?('account_manager', e)
  end

  def test_transitive_from_authorizer_is_role_of?
    u = User.new(:name => 'foo')
    assert u.save
    
    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save
    assert e.users.length == 1
    assert u.is_account_manager_of?(e)
  end

  def test_transitive_from_authorizable_twice_removed
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    assert i.users.length == 1
    assert i.has_account_managers.length == 1
    assert i.has_account_managers?
  end

  def test_transitive_from_authorizer_has_role_twice_removed
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    assert i.users.length == 1
    assert i.has_account_managers.length == 1
    assert u.has_role?('account_manager', i)
  end

  def test_transitive_from_authorizer_has_role_twice_removed
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    assert i.users.length == 1
    assert i.has_account_managers.length == 1
    assert u.has_role?('account_manager', i)
  end

  def test_transitive_authorizables_for
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save
    
    co = Contact.new(:name => 'barney', :client => c)
    assert co.save
    
    auths = u.authorizables_for(Client)
    assert auths
    assert auths.length == 1
    assert auths[0].class == Client

    auths = u.authorizables_for(Enterprise)
    assert auths
    assert auths.length == 1
    assert auths[0].class == Enterprise

    auths = u.authorizables_for(Instance)
    assert auths
    assert auths.length == 1
    assert auths[0].class == Instance

    auths = u.authorizables_for(Contact)
    assert auths
    assert auths.length == 1
    assert auths[0].class == Contact
  end

  def test_transitive_from_authorizer_has_roles_for?
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    assert u.has_roles_for?(c)
    assert u.has_roles_for?(e)
    assert u.has_roles_for?(i)
  end

  def test_transitive_from_authorizer_roles_for
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    roles = u.roles_for(c)
    assert_equal roles, u.roles_for(e)
    assert_equal roles, u.roles_for(i)
  end

  def test_transitive_from_authorizer_is_thing_of
    u = User.new(:name => 'foo')
    assert u.save

    c = Client.new(:name => 'bar')
    assert c.save

    u.has_role 'account_manager', c
    assert u.has_role?('account_manager')
    assert u.has_role?('account_manager', c)

    e = Enterprise.new(:name => 'baz', :client => c)
    assert e.save

    i = Instance.new(:name => 'fred', :enterprise => e)
    assert i.save

    assert u.is_account_manager_for?(c)
    assert u.is_account_manager_for?(e)
    assert u.is_account_manager_for?(i)
  end

end
