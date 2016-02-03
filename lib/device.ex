defmodule BlinkyPresence.Device do
  use GenServer
  alias BlinkyPresence.Service
  alias Phoenix.PubSub

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    pubsub_server = Keyword.fetch!(opts, :pubsub_server)
    color         = System.get_env("COLOR") || raise "no color specified for device"
    ref           = make_ref()

    Service.subscribe(pubsub_server, self(), :led)

    Service.register(self(), :led, %{color: color, ref: ref})
    {:ok, %{ref: ref, pubsub_server: pubsub_server}}
  end

  def handle_info({:join, :led, %{ref: ref} = meta}, %{ref: my_ref} = state)
    when ref != my_ref do

    IO.puts "led join with color #{meta.color}"
    {:noreply, state}
  end
  def handle_info({:join, _type, _meta}, state) do
    {:noreply, state}
  end

  def handle_info({:leave, :led, %{ref: ref} = meta}, %{ref: my_ref} = state)
    when ref != my_ref do

    IO.puts "led leave with color #{meta.color}"
    {:noreply, state}
  end
  def handle_info({:leave, _type, _meta}, state) do
    {:noreply, state}
  end
end
