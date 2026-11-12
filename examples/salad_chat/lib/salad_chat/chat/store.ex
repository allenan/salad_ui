defmodule SaladChat.Chat.Store do
  @moduledoc """
  The in-memory database: a handful of ETS tables owned by this process.

  Reads go straight to ETS from any process. Writes run inside this process
  via `run/1`, so they are serialized. Everything is seeded on boot from
  `SaladChat.Chat.Seed` and lost on restart.
  """
  use GenServer

  alias SaladChat.Chat.Seed

  @users :salad_chat_users
  @channels :salad_chat_channels
  @messages :salad_chat_messages
  @reads :salad_chat_reads
  @meta :salad_chat_meta

  def users, do: @users
  def channels, do: @channels
  def messages, do: @messages
  def reads, do: @reads

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Runs `fun` inside the store process (the only writer)."
  def run(fun) when is_function(fun, 0), do: GenServer.call(__MODULE__, {:run, fun})

  @doc "Wipes every table and seeds again."
  def reset!, do: GenServer.call(__MODULE__, :reset)

  @doc "Allocates the next message id. Call inside `run/1`."
  def next_id, do: :ets.update_counter(@meta, :next_id, 1)

  ## Callbacks

  @impl true
  def init(_opts) do
    :ets.new(@users, [:set, :protected, :named_table, read_concurrency: true])
    :ets.new(@channels, [:set, :protected, :named_table, read_concurrency: true])
    :ets.new(@messages, [:ordered_set, :protected, :named_table, read_concurrency: true])
    :ets.new(@reads, [:set, :protected, :named_table, read_concurrency: true])
    :ets.new(@meta, [:set, :protected, :named_table])
    seed()
    {:ok, %{}}
  end

  @impl true
  def handle_call({:run, fun}, _from, state), do: {:reply, fun.(), state}

  def handle_call(:reset, _from, state) do
    Enum.each([@users, @channels, @messages, @reads, @meta], &:ets.delete_all_objects/1)
    seed()
    {:reply, :ok, state}
  end

  defp seed do
    %{users: users, channels: channels, messages: messages, reads: reads} =
      Seed.build(DateTime.utc_now())

    :ets.insert(@users, Enum.map(users, &{&1.handle, &1}))
    :ets.insert(@channels, Enum.map(channels, &{&1.id, &1}))
    :ets.insert(@messages, Enum.map(messages, &{&1.id, &1}))
    :ets.insert(@reads, Enum.map(reads, fn {key, id} -> {key, id} end))

    max_id = messages |> Enum.map(& &1.id) |> Enum.max(fn -> 0 end)
    :ets.insert(@meta, {:next_id, max_id})
  end
end
