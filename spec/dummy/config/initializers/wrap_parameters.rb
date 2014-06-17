# Disable parameter wrapping for JSON.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end

# Ensable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = true
end
