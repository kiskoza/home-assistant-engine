defmodule HomeAssistantEngine.Client do
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, %{id: 0})
  end

  def handle_connect(_conn, state) do
    IO.puts("connected")
    {:ok, state}
  end

  def handle_disconnect(_connection_status_map, state) do
    IO.puts("disconnected")
    {:ok, state}
  end

  def handle_frame({type, msg}, %{id: id} = state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "auth_required"}} ->
        {:ok, reply} =
          Jason.encode(%{
            type: "auth",
            access_token: Application.get_env(:home_assistant_engine, __MODULE__)[:token]
          })

        {:reply, {:text, reply}, state}

      {:ok, %{"type" => "auth_ok"}} ->
        {:ok, reply} =
          Jason.encode(%{
            id: id + 1,
            type: "get_states"
          })

        {:reply, {:text, reply}, %{state | id: id + 1}}

      _ ->
        IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
        {:ok, state}
    end
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end
end
