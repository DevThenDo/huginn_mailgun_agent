require 'mailgun-ruby'

module Agents

  class Mysql2AgentConnection < ActiveRecord::Base
      def self.abstract_class?
        true # So it gets its own connection
      end
  end

  class MailgunAgent < Agent

    can_dry_run!
    no_bulk_receive!
    default_schedule "never"
    
    description <<-MD
      Add a Agent description here
    MD

    def default_options
      {
        'connection_url' => 'mysql2://user:pass@localhost/database',
        'sql' => 'select * from table_name order by id desc limit 30',
        'merge_event' => 'false',
        'mailgun_apikey' => '',
        'from_address' => 'test@example.com',
        'testing_mode' => 'false'
      }
    end


    form_configurable :connection_url
    form_configurable :sql, type: :text, ace: {:mode =>'sql', :theme => ''}
    form_configurable :merge_event, type: :boolean
    form_configurable :testing_mode, type: :boolean
    form_configurable :mailgun_apikey, type: :text
    form_configurable :from_address, type: :text
    
    def validate_options

      if options['merge_event'].present? && !%[true false].include?(options['merge_event'].to_s)
        errors.add(:base, "Oh no!!! if provided, merge_event must be 'true' or 'false'")
      end
      errors.add(:base, "Mailgun API Key Missing") unless options['mailgun_apikey'].present?
      errors.add(:base, "Missing From Address") unless options['from_address'].present?
    end
    end

    def working?
      !recent_error_logs?
    end

    def check
      handle(interpolated)
    end

    def receive(incoming_events)
      incoming_events.each do |event|
          handle(interpolated(event), event)
      end
    end
    
    private
   
    def handle(opts, event = Event.new)
       t1 = Time.now
       connection_url = opts["connection_url"]
       sql = opts["sql"]
 
       begin
         conn = Mysql2AgentConnection.establish_connection(connection_url).connection
         mg_client = Mailgun::Client.new(options['mailgun_apikey'])
         if options['testing_mode'] == true mg_client.enable_test_mode! 
         results = conn.exec_query(sql)
         results.each do |row|
           # merge with incoming event
           # if boolify(interpolated['merge_event']) and event.payload.is_a?(Hash)
           #   row = event.payload.deep_merge(row)
           # end
           # create_event payload: row
         end 
         if results.present?
          conn.close
 
         log("Time: #{(Time.now - t1).round(2)}s, results.length: #{results.length if results.present?}, \n sql: \n #{sql}")
 
       rescue => error
         error "Error connection: #{error.inspect}"
         return
       end
 
     end
  end
end
