# frozen_string_literal: true

ActiveSupport.on_load(:solid_cache_entry) do
  encrypts :value
end
