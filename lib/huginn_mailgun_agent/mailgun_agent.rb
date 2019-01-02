require 'mailgun-ruby'

module Agents

  class Mysql2AgentConnection < ActiveRecord::Base
      def self.abstract_class?
        true # So it gets its own connection
      end
  end

  class MailgunAgent < Agent

    include FormConfigurable
    
    can_dry_run!
    no_bulk_receive!
    default_schedule "never"
    
    description <<-MD
    Sends bulk transactional emails via MailGun. Uses a Database connection to retrieve the recipients
    
    To send emails to users, first create a Database and table to hold your recipients. 
    
    `connection_url` is the database connection you want to use
    
    `sql` should be the Select Query to select your users. It must return a `name` and `email` field. eg: `select name, email from users`
    
    `mailgun_apikey` is your MailGun Private Key
    
    `mailgun_domain` is the domain you wish to use with Mailgun
    
    `mailgun_tracking` will enable both Open and Click Tracking in your emails (if enabled on your Mailgun Domain Account)
    
    `testing_mode` will submit the messages to Mailgun, but not actually send the emails to the recipients
    
    `from_address` is the address you want to the emails to come from (can be overridden in a event payload)
    
    If `merge_event` is true, then the Mailgun Message ID is merged with the original payload
    
    Payload Fields:
    
     * `from_address` allows you to override the default from message. Should be in this format: `name <email@address.com>`
    
     * `subject` is the email Subject
    
     * `message` is the Email Body (can be HTML if you want to enable tracking)
    
     * `tags` is either a single Tag or a array or Tags that you can use for Analytics on the MailGun Site
    MD

    def default_options
      {
        'connection_url' => 'mysql2://user:pass@localhost/database',
        'sql' => 'select email, name from emails order by id desc',
        'merge_event' => 'false',
        'mailgun_apikey' => '',
        'from_address' => 'test@example.com',
        'testing_mode' => 'false',
        'mailgun_domain' => '',
        'mailgun_tracking' => 'false',
      }
    end


    form_configurable :mailgun_apikey, type: :text
    form_configurable :mailgun_domain, type: :text
    form_configurable :from_address, type: :text
    form_configurable :connection_url
    form_configurable :sql, type: :text, ace: {:mode =>'sql', :theme => ''}
    form_configurable :merge_event, type: :boolean
    form_configurable :mailgun_tracking, type: :boolean
    form_configurable :testing_mode, type: :boolean
    
    def validate_options

      if options['merge_event'].present? && !%[true false].include?(options['merge_event'].to_s)
        errors.add(:base, "Oh no!!! if provided, merge_event must be 'true' or 'false'")
      end
      errors.add(:base, "Mailgun API Key Missing") unless options['mailgun_apikey'].present?
      errors.add(:base, "Missing From Address") unless options['from_address'].present?
      errors.add(:base, "Missing Mailgun Domain") unless options['mailgun_domain'].present?
        
    end

    def working?
      !recent_error_logs?
    end

    def check
      handle(interpolated)
    end

    def receive(incoming_events)
      incoming_events.each do |event|
          handle(interpolated(event), event.payload)
      end
    end
    
    private
   
    def handle(opts, event = Event.new)
       t1 = Time.now
       connection_url = opts["connection_url"]
       sql = opts["sql"]
 
       begin
         conn = Mysql2AgentConnection.establish_connection(connection_url).connection
         mg_client = Mailgun::Client.new(opts['mailgun_apikey'])
         bm_obj = Mailgun::BatchMessage.new(mg_client, opts['mailgun_domain'])
         bm_obj.test_mode(opts['testing_mode'])
         bm_obj.track_opens(opts['mailgun_tracking'])
         bm_obj.track_clicks(opts['mailgun_tracking'])
         bm_obj.subject(event['subject'])
         if event['msg-tag'].respond_to?('each')
           event['msg-tag'].each do | tag |
             bm_obj.add_tag(tag)
           end
         else
           bm_obj.add_tag(event['msg-tag'])
         end
         if event['from_address'].present?
           bm_obj.from(event['from_address'])
         else
           bm_obj.from(opts['from_address'])
         end
         bm_obj.body_html(event['message'])
         results = conn.exec_query(sql)
         results.each do |row|
           toaddr = row['name'] + " <" + row['email']  + ">"
           log("Sending to #{toaddr}")
           bm_obj.add_recipient(:to, toaddr)
         end 
         if results.present?
          conn.close
         end
         message_ids = bm_obj.finalize
         if (opts['merge_event'] == 'true')
          event['message_ids'] = message_ids
          create_event payload: event  
         else 
          create_event payload: message_ids
         end
         log("Time: #{(Time.now - t1).round(2)}s, Sent: #{results.length if results.present?}, #{pp message_ids}")
 
       rescue => error
         error "Error connection: #{error.inspect} - #{error.backtrace}"
         return
       end
 
     end
  end
end
