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

  def handle_cast(
        {:entity_changed, _, %{"entity_id" => "sun.sun", "state" => current_state}},
        {_, current_state} = state
      ) do
    {:noreply, state}
  end

  def handle_cast(
        {:entity_changed, _, %{"entity_id" => "sun.sun", "state" => new_state}},
        {pid, _}
      ) do
    HomeAssistantEngine.reply(pid, %{
      domain: "persistent_notification",
      service: "create",
      service_data: %{message: "The sun is #{new_state}"}
    })

    {:noreply, {pid, new_state}}
  end

  def handle_cast({:entity_changed, _, _}, state) do
    {:noreply, state}
  end

  def handle_call({:get_state}, _from, {_, status} = state) do
    {:reply, {status}, state}
  end
end
