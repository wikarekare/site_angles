# Return angles from towers to sites.
class Site_Angles < RPC
  def initialize(authenticated = false)
    super(authenticated)
    if authenticated
      @select_acl = []
      @result_acl = @select_acl + []
      @set_acl = []
      @create_acl = @result_acl
    else
      @select_acl = []
      @result_acl = []
      @set_acl = []
      @create_acl = []
    end
  end

  rmethod :read do |select_on: nil, set: nil, result: nil, order_by: nil, **args|
    # fill me in
  end
end
