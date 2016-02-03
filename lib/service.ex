defmodule BlinkyPresence.Service do
  @behaviour Phoenix.Tracker

  @topic "services"

  ## Client API

  def subscribe(pubsub_server, pid, type) do
    Phoenix.PubSub.subscribe(pubsub_server, pid, "#{@topic}:#{type}", link: true)
  end

  def register(pid, service_type, meta) do
    Phoenix.Tracker.track(__MODULE__, pid, @topic, service_type, meta)
  end

  def list(service_type) do
    __MODULE__
    |> Phoenix.Tracker.list(@topic)
    |> Stream.filter(fn {type, _meta} -> type == service_type end)
    |> Enum.map(fn {_type, meta} -> meta end)
  end


  ## Server API

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__, log_level: false], opts)
    GenServer.start_link(Phoenix.Tracker, [__MODULE__, opts, opts], name: __MODULE__)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}}  <- diff do
      for {type, meta} <- joins do
        IO.puts "service join: device type \"#{type}\" with meta #{inspect meta}"
        direct_broadcast(state, "#{topic}:#{type}", {:join, type, meta})
      end
      for {type, meta} <- leaves do
        IO.puts "service leave: device type \"#{type}\" with meta #{inspect meta}"
        direct_broadcast(state, "#{topic}:#{type}", {:leave, type, meta})
      end
    end
    {:ok, state}
  end

  defp direct_broadcast(state, topic, msg) do
    Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
  end
end
