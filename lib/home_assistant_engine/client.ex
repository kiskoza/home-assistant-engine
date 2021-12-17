defmodule HomeAssistantEngine.Client do
  use WebSockex

  def start_link({url, automations}) do
    # State is {id, pending, automations}
    WebSockex.start_link(url, __MODULE__, {0, [], automations})
  end

  def reply(pid, message) do
    WebSockex.cast(pid, {:send, {:type, message}})
    :ok
  end

  def handle_connect(_conn, {_, _, automations} = state) do
    IO.puts("connected")

    automations
    |> Enum.each(fn module -> GenServer.start_link(module, {:ok, self()}, name: module) end)

    {:ok, state}
  end

  def handle_disconnect(_connection_status_map, {_, _, automations} = state) do
    IO.puts("disconnected")

    automations
    |> Enum.each(fn module -> module.stop end)

    {:ok, state}
  end

  def handle_frame({type, msg}, {id, pending, automations} = state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "auth_required"}} -> auth_request(state)
      {:ok, %{"type" => "auth_ok"}} -> get_states_request(state)
      {:ok, %{"type" => "result", "success" => true} = response} ->
        {:ok, type, pending} = get_call_type(response["id"], pending, [])

        case type do
          :get_states ->
            handle_get_states(response, state)
            subscribe_events_request({id, pending, automations})

          :subscribe_events ->
            IO.puts("Successfully subscribed to events")
            {:ok, {id, pending, automations}}

          _ ->
            IO.puts("Unknown response #{inspect(type)} - #{inspect(msg)}")
            {:ok, {id, pending, automations}}
        end

      {:ok, %{"type" => "event"} = response} ->
        event_type = response["event"]["event_type"]

        case event_type do
          "state_changed" ->
            IO.puts("Got an event: #{inspect(response)}")
            %{"old_state" => old_entity, "new_state" => new_entity} = response["event"]["data"]

            automations |> Enum.each(fn module -> module.change_entity(old_entity, new_entity) end)
            {:ok, state}

          "call_service" ->
            IO.puts("Service called: #{inspect(response)}")
            {:ok, state}

          _ ->
            IO.puts("Unknown event: #{inspect(response)}")
            {:ok, state}
        end

      _ ->
        IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
        {:ok, state}
    end
  end

  def handle_cast({:send, {type, msg} = frame}, {id, pending, automations} = state) do
    id = id + 1

    {:ok, reply} = msg
    |> Map.put(:id, id)
    |> Map.put(:type, "call_service")
    |> Jason.encode()

    IO.puts("Sending json frame with payload: #{reply}")
    {:reply, {:text, reply}, {id, [{id, :call_service} | pending], automations }}
  end

  defp auth_request(state) do
    {:ok, reply} =
      Jason.encode(%{
        type: "auth",
        access_token: Application.get_env(:home_assistant_engine, __MODULE__)[:token]
      })

    {:reply, {:text, reply}, state}
  end

  defp get_states_request({id, pending, automations}) do
    id = id + 1
    IO.puts("Request current states")
    {:ok, reply} =
      Jason.encode(%{
        id: id,
        type: "get_states"
      })

    {:reply, {:text, reply}, {id, [{id, :get_states} | pending], automations}}
  end

  defp handle_get_states(%{"result" => results}, {_, _, automations}) do
    IO.puts("Got states")
    results
    |> Enum.each(fn result ->
      automations |> Enum.each(fn module -> module.set_entity(result) end)
    end)
  end

  defp subscribe_events_request({id, pending, automations}) do
    id = id + 1
    {:ok, reply} = Jason.encode(%{
      id: id,
      type: "subscribe_events"
    })

    {:reply, {:text, reply}, {id, [{id, :subscribe_events} | pending], automations}}
  end

  defp get_call_type(_, [], _) do
    {:error, :not_in_the_list}
  end
  defp get_call_type(id, [{id, type} | tail], remaining) do
    {:ok, type, remaining ++ tail}
  end
  defp get_call_type(id, [head | tail], remaining) do
    get_call_type(id, tail, [head | remaining])
  end
end
