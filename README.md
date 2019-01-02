# MailgunAgent

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

## Installation

This gem is run as part of the [Huginn](https://github.com/huginn/huginn) project. If you haven't already, follow the [Getting Started](https://github.com/huginn/huginn#getting-started) instructions there.

Add this string to your Huginn's .env `ADDITIONAL_GEMS` configuration:

```ruby
huginn_mailgun_agent
# when only using this agent gem it should look like this:
ADDITIONAL_GEMS=huginn_mailgun_agent
```

And then execute:

    $ bundle


## Contributing

1. Fork it ( https://github.com/DevThenDo/huginn_mailgun_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
