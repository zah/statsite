def service_name
  if new_resource.name == "default"
    "statsite"
  else
    "statsite_#{new_resource.name}"
  end
end

action :create do
  # install dependencies
  @run_context.include_recipe "git"
  @run_context.include_recipe "build-essential"
  @run_context.include_recipe "python"
  package "scons"

  # build statsite
  ref = new_resource.ref
  path = "#{node.statsite.path}/#{ref}"
  conf = "/etc/#{service_name}.conf"

  git path do
    repository node.statsite.repo
    reference ref
    action :checkout
  end

  execute "scons" do
    cwd path
    action  :run
    creates "statsite"
  end

  # create a user/group pair for running the service
  group new_resource.owner do
    system true
    action :create
  end

  user new_resource.owner do
    system true
    group new_resource.group
  end

  # create the system service
  case new_resource.service_type
  when 'upstart'
    template "/etc/init/#{service_name}.conf" do
      source   "upstart.statsite.erb"
      mode     "0644"
      variables(
        :conf    => node[:statsite][:conf],
        :path    => path,
        :user    => new_resource.owner,
        :group   => new_resource.group
      )
    end

    service service_name do
      provider Chef::Provider::Service::Upstart
      supports :restart => true, :status => true
      action :create
    end
  else
    @run_context.include_recipe "runit"

    runit_service service_name do
      cookbook "statsite"
      run_template_name "statsite"
      log_template_name "statsite"
      action :enable
      options(
        :service_name => service_name,
        :statsite_path => path,
        :conf => conf)
    end
  end

  # create the statsite configuration
  template conf do
    cookbook "statsite"
    source "statsite.conf.erb"
    owner new_resource.owner
    # notifies :restart, "service[#{service_name}]", :delayed
    variables(
      :port => new_resource.port,
      :loglevel => new_resource.loglevel,
      :flush_interval => new_resource.flush_interval,
      :timer_eps => new_resource.timer_eps,
      :stream_command => new_resource.stream_command)
  end
end

# forward all commands to the installed service
for command in [:enable, :disable, :start, :stop, :reload, :restart]
  action command do
    case new_resource.service_type
    when 'upstart'
      service service_name do
        action command
      end
    else
      runit_service service_name do
        action command
      end
    end
  end
end

