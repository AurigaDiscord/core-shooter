use Mix.Config

config :shooter,
  bot_token:            {:system, "BOT_TOKEN"},
  amqp_path:            {:system, "AMQP_PATH", "amqp://guest:guest@localhost"},
  amqp_exchange:        {:system, "AMQP_EXCHANGE", "topic"},
  amqp_queue_outcoming: {:system, "AMQP_QUEUE_OUTCOMING", "outcoming"},
  amqp_key_outcoming:   {:system, "AMQP_KEY_OUTCOMING", "outcoming"}

config :logger, :console,
  level: :info,
  format: "$date $time $metadata[$level] $levelpad$message\n"
