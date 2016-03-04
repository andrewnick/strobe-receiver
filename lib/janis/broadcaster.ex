defmodule Janis.Broadcaster do
  use Supervisor

  @supervisor_name Janis.Broadcaster
  @child_name Janis.Broadcaster

  defstruct [
    :hostname,
    :port,
    :ip,
    :ctrl_port,
    :data_port,
    :stream_interval,
    :packet_size,
  ]

  alias __MODULE__

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @supervisor_name)
  end

  def start_broadcaster(hostname, port, config) do
    start_broadcaster(@supervisor_name, hostname, port, config)
  end

  def start_broadcaster(supervisor, hostname, port, config) do
    Supervisor.start_child(supervisor, [ new(hostname, port, config) ])
  end

  def stop_broadcaster(service) do
    stop_broadcaster(@supervisor_name, service)
  end

  def stop_broadcaster(supervisor, _service) do
    Supervisor.which_children(supervisor) |> terminate_broadcasters(supervisor)
  end

  def terminate_broadcasters([child | children], supervisor) do
    case child do
    {_id, :restarting, _worker, _modules} ->
      :ok
    {_id, :undefined, _worker, _modules} ->
      :ok
    {_id, pid, _worker, _modules} ->
      terminate_broadcaster(supervisor, pid)
    end
    terminate_broadcasters(children, supervisor)
  end

  def terminate_broadcasters([], _supervisor) do
  end

  def terminate_broadcaster(supervisor, broadcaster) do
    :ok = Supervisor.terminate_child(supervisor, broadcaster)
  end

  def init(:ok) do
    children = [
      supervisor(Janis.Broadcaster.Supervisor, [], [])
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def new(hostname, port, config) do
    {:ok, ip} = Janis.Network.lookup(hostname)
    struct(%Broadcaster{
      hostname: hostname,
      ip: ip,
      port: port
    }, config)
  end

  def stream_interval_ms(broadcaster) do
    round(broadcaster.stream_interval / 1000.0)
  end
end
