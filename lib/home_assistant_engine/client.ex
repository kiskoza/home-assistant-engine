defmodule HomeAssistantEngine.Client do
  use WebSockex

  def start_link([url, state]) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  def handle_connect(_conn, state) do
    IO.puts "connected"
    {:ok, state}
  end

  def handle_disconnect(_connection_status_map, state) do
    IO.puts "disconnected"
    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    IO.puts("Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}")
    {:ok, state}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts("Sending #{type} frame with payload: #{msg}")
    {:reply, frame, state}
  end
end
