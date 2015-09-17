defmodule Janis.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(Janis.DNSSD, []),
      worker(Janis.Player.Output, []),
      supervisor(Janis.Broadcasters, [])
      # worker(Janis.Resources, []),
    ]
    supervise(children, strategy: :one_for_one)
  end
end
