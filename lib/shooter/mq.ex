defmodule Shooter.MQ do
  require Logger
  use GenServer
  use AMQP
  alias Shooter.Client

  def start_link do
    GenServer.start_link(__MODULE__, [], name: Shooter.MQ)
  end

  def init(_) do
    {:ok, chan, queue, exchange} = mq_connect
    state = %{
      :chan     => chan,
      :queue    => queue,
      :exchange => exchange,
    }
    {:ok, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    {:stop, :normal, state}
  end
  # Message delivery
  def handle_info({:basic_deliver, payload, %{delivery_tag: tag}}, state) do
    spawn fn -> consume(state[:chan], tag, payload) end
    {:noreply, state}
  end
  # Channel process is down
  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    {:ok, chan, queue, key_parsed, exchange} = mq_connect
    {:noreply, %{state | :chan       => chan,
                         :queue      => queue,
                         :exchange   => exchange}}
  end
  # Catch-all
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp generate_mq_vars do
    mq_path = Application.get_env(:shooter, :amqp_path)
    cfg_queue = Application.get_env(:shooter, :amqp_queue_outcoming)
    cfg_key = Application.get_env(:shooter, :amqp_key_outcoming)
    cfg_exchange = Application.get_env(:shooter, :amqp_exchange)

    exchange = "auriga.#{cfg_exchange}"
    queue = "#{exchange}.#{cfg_queue}"
    queue_error = "#{exchange}.error"
    key = "auriga.#{cfg_key}"

    {:ok, mq_path, queue, queue_error, key, exchange}
  end

  defp mq_connect do
    {:ok, mq_path, queue, queue_error, key, exchange} = generate_mq_vars
    mq_path_censored = Regex.replace(~r/:[^\/].+@/, mq_path, ":[REDACTED]@")
    Logger.info("Connecting to AMQP server at #{mq_path_censored}")

    case Connection.open(mq_path) do
      {:ok, conn} ->
        Process.monitor(conn.pid)
        {:ok, chan} = Channel.open(conn)
        Basic.qos(chan, prefetch_count: 10)
        setup_queue(chan, queue, queue_error, key, exchange)
        {:ok, _consumer_tag} = Basic.consume(chan, queue)
        Logger.info("Connected")
        {:ok, chan, queue, exchange}
      {:error, error} ->
        Logger.error("AMQP connection problem: #{inspect error}")
        :timer.sleep(5000)
        mq_connect
    end
  end

  defp setup_queue(chan, queue, queue_error, key, exchange) do
    Queue.declare(chan, queue, durable: true,
                               routing_key: key,
                               arguments: [{"x-dead-letter-exchange", :longstr, ""},
                                           {"x-dead-letter-routing-key", :longstr, queue_error}])
    Queue.bind(chan, queue, exchange, routing_key: key)
  end

  defp consume(chan, tag, payload) do
    Client.process(payload)
    Basic.ack(chan, tag)
  end

end
