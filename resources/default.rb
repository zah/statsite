actions :create, :enable, :start, :stop, :reload, :restart, :disable, :remove

def initialize(*args)
  super
  @action = [:create, :enable, :start]
end

attribute :name,
  :name_attribute => true

attribute :owner,
  :default => node.statsite.owner

attribute :group,
  :default => node.statsite.group

attribute :ref,
  :default => node.statsite.ref

attribute :port,
  :default => node.statsite.port

attribute :flush_interval,
  :default => node.statsite.flush_interval

attribute :loglevel,
  :default => node.statsite.loglevel

attribute :stream_command,
  :default => node.statsite.stream_command

attribute :service_type,
  :default => node.statsite.service_type

attribute :timer_eps,
  :default => node.statsite.timer_eps

