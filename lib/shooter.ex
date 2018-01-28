defmodule Shooter do
  require Logger
  use Application

  def start(_type, _args) do
    Logger.info "Starting shooter application"
    Confex.resolve_env!(:shooter)

    import Supervisor.Spec, warn: false
    sup_children = [
      worker(Shooter.MQ, []),
    ]
    sup_opts = [strategy: :one_for_one, name: Shooter.Supervisor]
    Supervisor.start_link(sup_children, sup_opts)
  end

end
