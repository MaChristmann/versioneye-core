class SendNotificationEmailsProducer < Producer

  def initialize msg
    connection = get_connection
    connection.start

    channel = connection.create_channel
    queue   = channel.queue("send_notification_emails", :durable => true)

    queue.publish(msg, :persistent => true)

    log_msg = " [x] Sent #{msg}"
    puts log_msg
    log.info log_msg

    connection.close
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end