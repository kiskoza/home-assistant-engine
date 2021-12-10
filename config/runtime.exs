import Config
import Dotenvy

source([".env", ".env.#{config_env()}", ".env.#{config_env()}.local"])

config :home_assistant_engine, HomeAssistantEngine.Client, token: env!("TOKEN", :string!)
