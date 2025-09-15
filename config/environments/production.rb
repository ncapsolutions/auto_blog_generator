require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Enable caching
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Assets
  config.assets.compile = false # Always precompile assets in production

  # Storage
  config.active_storage.service = :local

  # Force SSL
  config.assume_ssl = true
  config.force_ssl = true

  # Logging
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"

  # Deprecations
  config.active_support.report_deprecations = false

  # Active Job with Sidekiq
  config.active_job.queue_adapter = :sidekiq

  # Mailer setup
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host: "modern-blog-74qm.onrender.com",
    protocol: "https"
  }
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    address: ENV['SMTP_ADDRESS'],   # e.g., sandbox.smtp.mailtrap.io
    port: ENV['SMTP_PORT'] || 2525,
    authentication: :login,
    enable_starttls_auto: true
  }

  # I18n
  config.i18n.fallbacks = true

  # Active Record
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]
end
