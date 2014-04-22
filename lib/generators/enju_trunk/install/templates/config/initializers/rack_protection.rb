Rails.application.config.middleware.use Rack::Protection,
  except: [:escaped_params, :json_csrf, :session_hijacking]
