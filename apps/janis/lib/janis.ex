defmodule Janis do
  require Logger

  @sample_freq        Application.get_env(:janis, :sample_freq, 44100)
  @sample_bits        Application.get_env(:janis, :sample_bits, 16)
  @sample_channels    Application.get_env(:janis, :sample_channels, 2)

  @uuid_namespace     "39cd3e2a-b9ce-4e12-ba7a-d6f828cac1b3"

  def start(_type, _args) do
    Janis.Supervisor.start_link
  end

  def sample_freq, do: @sample_freq
  def sample_bits, do: @sample_bits
  def sample_channels, do: @sample_channels

  def receiver_id do
    UUID.uuid5(@uuid_namespace, id_from_ifs(:inet.getifaddrs))
  end

  defp id_from_ifs({:ok, ifs}) do
    ifs
    |> valid_ifs
    |> Enum.sort_by(fn({name, _opts}) -> name end)
    |> List.first
    |> id_from_if
  end

  def valid_ifs do
    {:ok, ifs} = IO.inspect(:inet.getifaddrs)
    valid_ifs(ifs)
  end

  def valid_ifs(ifs) do
    Enum.filter ifs, fn({name, opts}) ->
      valid_if_name?(name) && valid_if_addrs?(opts)
    end
  end

  def valid_if_name?('lo'), do: false
  def valid_if_name?(_name), do: true

  def valid_if_addrs?(opts) do
    Enum.all? [:hwaddr], fn(key) ->
      Keyword.has_key?(opts, key)
    end
  end

  def id_from_if({_name, _opts} = iface) do
    Enum.map(hwaddr(iface), fn(b) ->
      Integer.to_string(b, 16) |> String.downcase |> String.rjust(2, ?0)
    end) |> Enum.join("-")
  end

  def id_from_if(iface) do
    Logger.warn "No interface id calculated for #{ inspect iface }"
    :error
  end

  # Give the loopback device a valid mac address
  def hwaddr({'lo' ++ _, _opts}) do
    [0, 0, 0, 0, 0, 0]
  end

  def hwaddr({_name, opts}) do
    opts[:hwaddr]
  end

  def sanitize_volume(volume) when is_integer(volume), do: sanitize_volume(volume + 0.0)
  def sanitize_volume(volume) when volume > 1.0, do: 1.0
  def sanitize_volume(volume) when volume < 0.0, do: 0.0
  def sanitize_volume(volume), do: volume

  def set_logger_metadata do
    Logger.metadata(receiver_id: receiver_id())
  end
end
