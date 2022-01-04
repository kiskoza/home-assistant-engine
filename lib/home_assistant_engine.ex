defmodule HomeAssistantEngine do
  use WebSockex

  def start_link({url, automations}) do
    # State is {id, pending, automations}
    WebSockex.start_link(url, HomeAssistantEngine.Client, {0, [], automations})
  end

  def reply(pid, message) do
    WebSockex.cast(pid, {:send, {:text, message}})
    :ok
  end
end
