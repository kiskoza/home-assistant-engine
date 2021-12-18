defmodule Automations.SunLoggerTest do
  use ExUnit.Case

  setup do
    start_supervised!({Automations.SunLogger, {:ok, self()}})
    :ok
  end

  test "use unknow for initial state" do
    assert Automations.SunLogger.get_state() == {"unknown"}
  end

  test "saves the state of sun.sun entity" do
    Automations.SunLogger.set_entity(%{"entity_id" => "sun.sun", "state" => "below_horizon"})

    assert Automations.SunLogger.get_state() == {"below_horizon"}
  end

  test "does not change the state for other entities" do
    Automations.SunLogger.set_entity(%{"entity_id" => "other.entity", "state" => "something_else"})

    assert Automations.SunLogger.get_state() == {"unknown"}
  end

  test "handles multiple calls" do
    Automations.SunLogger.set_entity(%{"entity_id" => "sun.sun", "state" => "below_horizon"})
    Automations.SunLogger.set_entity(%{"entity_id" => "sun.sun", "state" => "above_horizon"})
    Automations.SunLogger.set_entity(%{"entity_id" => "other.entity", "state" => "something_else"})

    assert Automations.SunLogger.get_state() == {"above_horizon"}
  end

  test "handles change entity action" do
    Automations.SunLogger.set_entity(%{"entity_id" => "sun.sun", "state" => "below_horizon"})
    Automations.SunLogger.change_entity(%{}, %{"entity_id" => "sun.sun", "state" => "above_horizon"})

    assert Automations.SunLogger.get_state() == {"above_horizon"}
    assert_received {_, {:send, {:text, %{domain: "persistent_notification", service: "create", service_data: %{message: "The sun is above_horizon"}}}}}
  end

  test "handles change entity action when the state remained the same" do
    Automations.SunLogger.set_entity(%{"entity_id" => "sun.sun", "state" => "below_horizon"})
    Automations.SunLogger.change_entity(%{}, %{"entity_id" => "sun.sun", "state" => "below_horizon"})

    assert Automations.SunLogger.get_state() == {"below_horizon"}
    refute_received {_, {:send, {:text, _}}}
  end
end
