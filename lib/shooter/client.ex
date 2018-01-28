defmodule Shooter.Client do
  require Logger

  @type_text "text"

  def process(msg) do
    {:ok, decoded} = Poison.Parser.parse(msg, keys: :atoms)
    action(decoded)
  end

  defp action(%{:type => @type_text} = msg) do
    token = Application.get_env(:shooter, :bot_token)
    channel = msg[:channel_id]
    content = msg[:content]

    http_url = "https://discordapp.com/api/v6/channels/#{channel}/messages"
    http_headers = [
      "Accept": "application/json; charset=utf-8",
      "Authorization": "Bot #{token}",
      "Content-Type": "application/json",
      "User-Agent": "Auriga (https:://github.com/AurigaDiscord, v0.1.0)",
    ]
    {:ok, payload} = Poison.encode(%{content: content})
    {:ok, response} = HTTPoison.post(http_url, payload, http_headers)
    Logger.info("#{inspect response}")
    :ok
  end
  defp action(_) do
    :ok
  end
  
end
