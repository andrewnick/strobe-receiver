defmodule Janis.Player.Buffer do
  use     GenServer
  require Logger

  @moduledoc """
  Receives data from the buffer and passes it onto the playback process on demand
  """

  defmodule S do
    defstruct queue:       :queue.new,
              player:      nil,
              stream_info: nil,
              status:      :stopped
  end

  def start_link(stream_info, name) do
    GenServer.start_link(__MODULE__, stream_info, name: name)
  end

  def link_player(buffer, player) do
    GenServer.cast(buffer, {:link_player, player})
  end

  def get(buffer) do
    GenServer.call(buffer, :get)
  end

  def put(buffer, packet) do
    GenServer.cast(buffer, {:put, packet})
  end

  def init(stream_info) do
    Logger.debug "Player.Buffer up"
    Process.flag(:trap_exit, true)
    {:ok, %S{stream_info: stream_info}}
  end

  def handle_cast({:link_player, player}, %S{queue: queue} = state) do
    {:noreply, %S{state | player: player}}
  end

  def handle_cast({:put, packet}, %S{queue: queue, player: player, status: status} = state) do
    {queue, status} = put_packet(queue, packet, player, status)
    {:noreply, %{state | queue: queue, status: status}}
  end

  def handle_call(:get, _from, %S{queue: queue} = state) do
    {packet, queue} = :queue.out(queue)
    case next_packet(packet) do
      {:ok, _value} = success ->
        {:reply, success, %S{state | queue: queue}}
      {:error, _reason} = err ->
        {:reply, err, %S{state | queue: queue, status: :stopped}}
    end
  end

  def next_packet({:value, packet}) do
    {:ok, packet}
  end

  def next_packet(:empty) do
    Logger.warn "Buffer underrun"
    {:error, :empty}
  end

  def put_packet(queue, packet, player, :stopped) do
    player_start_playback(player)
    put_packet(queue, packet, player, :playing)
  end

  def put_packet(queue, packet, player, :playing) do
    Logger.debug "put #{Janis.milliseconds}"
    case :queue.len(queue) do
      l when l == 0 ->
        Logger.warn "Low buffer! #{inspect (l + 1)}"
      l when l > 20 ->
        Logger.warn "Overflow buffer! #{inspect (l + 1)}"
      _ ->
    end
    translated_packet = {timestamp, _data} = Janis.Broadcaster.translate_packet(packet)
    {:queue.in(translated_packet, queue), :playing}
  end

  def player_start_playback(nil) do
  end

  def player_start_playback(player) do
    Logger.debug "Player start playback..."
    Janis.Player.Player.start_playback(player)
  end

  def terminate(reason, state) do
    Logger.info "Stopping #{__MODULE__}"
    :ok
  end
end

