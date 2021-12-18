# Test with this data:
# %{"attributes" => %{"azimuth" => 242.46, "elevation" => -6.13, "friendly_name" => "Sun", "next_dawn" => "2021-12-11T05:43:13.851580+00:00", "next_dusk" => "2021-12-10T15:30:53.574281+00:00", "next_midnight" => "2021-12-10T22:37:11+00:00", "next_noon" => "2021-12-11T10:36:57+00:00", "next_rising" => "2021-12-11T06:19:08.587083+00:00", "next_setting" => "2021-12-11T14:55:02.197506+00:00", "rising" => false}, "context" => %{"id" => "a6f0fbf8b4907f1cb643ea7572989424", "parent_id" => nil, "user_id" => nil}, "entity_id" => "sun.sun", "last_changed" => "2021-12-10T15:21:56.609852+00:00", "last_updated" => "2021-12-10T15:29:40.828520+00:00", "state" => "below_horizon"}

defmodule Automations.SunLogger do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def set_entity(entity) do
    GenServer.cast(__MODULE__, {:set_entity, entity})
    :ok
  end

  def change_entity(old_entity, new_entity) do
    GenServer.cast(__MODULE__, {:entity_changed, old_entity, new_entity})
    :ok
  end

  def get_state() do
    GenServer.call(__MODULE__, {:get_state})
  end

  # Private

  def init({:ok, pid}) do
    {:ok, {pid, "unknown"}}
  end

  def handle_cast({:set_entity, %{"entity_id" => "sun.sun", "state" => new_sun_state}}, {pid, _}) do
    {:noreply, {pid, new_sun_state}}
  end

  def handle_cast({:set_entity, %{"entity_id" => _}}, state) do
    {:noreply, state}
  end

  def handle_cast({:entity_changed, _, %{"entity_id" => "sun.sun", "state" => current_state}}, {_, current_state} = state) do
    {:noreply, state}
  end

  def handle_cast({:entity_changed, _, %{"entity_id" => "sun.sun", "state" => new_state}}, {pid, _}) do
    HomeAssistantEngine.Client.reply(pid, %{domain: "persistent_notification", service: "create", service_data: %{message: "The sun is #{new_state}"}})
    {:noreply, {pid, new_state}}
  end

  def handle_cast({:entity_changed, _, _}, state) do
    {:noreply, state}
  end

  def handle_call({:get_state}, _from, {_, status} = state) do
    {:reply, {status}, state}
  end
end
