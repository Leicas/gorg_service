require "gorg_message_sender"
require "gorg_service/configuration"
require "gorg_service/version"
require "gorg_service/errors"
require "gorg_service/listener"
require "gorg_service/message"
require "gorg_service/message_handler"

#Duplicate GorgMessageSender to avoid configuration conflict
RabbitmqProducer=GorgMessageSender.dup

class GorgService
  def initialize(listener: nil, bunny_session: nil)

    @bunny_session= bunny_session || Bunny.new(
      :hostname => GorgService.configuration.rabbitmq_host,
      :port => GorgService.configuration.rabbitmq_port,
      :user => GorgService.configuration.rabbitmq_user,
      :pass => GorgService.configuration.rabbitmq_password,
      :vhost => GorgService.configuration.rabbitmq_vhost
      )

    @listener= listener || Listener.new(
      bunny_session: @bunny_session,
      message_handler_map:GorgService.configuration.message_handler_map,
      queue_name: GorgService.configuration.rabbitmq_queue_name,
      exchange_name: GorgService.configuration.rabbitmq_exchange_name,
      deferred_time: GorgService.configuration.rabbitmq_deferred_time,
      max_attempts: GorgService.configuration.rabbitmq_max_attempts,
      log_routing_key: GorgService.configuration.log_routing_key
      )

    RabbitmqProducer.configure do |c|
      # Id used to set the event_sender_id
      c.application_id = GorgService.configuration.application_id

      # RabbitMQ network and authentification
      c.host = GorgService.configuration.rabbitmq_host
      c.port = GorgService.configuration.rabbitmq_port
      c.vhost = GorgService.configuration.rabbitmq_vhost
      c.user = GorgService.configuration.rabbitmq_user
      c.password = GorgService.configuration.rabbitmq_password

      # Exchange configuration
      c.exchange_name = GorgService.configuration.rabbitmq_exchange_name
      c.durable_exchange= true      
    end

  end

  def run
    begin
      self.start
      puts " [*] Waiting for messages. To exit press CTRL+C"
      loop do
        sleep(1)
      end
    rescue SystemExit, Interrupt => _
      self.stop
    end
  end

  def start
    @bunny_session.start
    @listener.listen
  end

  def stop
    @bunny_session.close
  end
end
