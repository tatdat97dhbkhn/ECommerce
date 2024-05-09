# frozen_string_literal: true

require 'solid_queue'

SERVERS_BY_APP = {
  E_commerce: %w[solid_queue],
}.freeze

SERVERS_BY_APP.each do |app, servers|
  queue_adapters_by_name = servers.to_h do |server|
    queue_adapter = ActiveJob::QueueAdapters::SolidQueueAdapter.new

    [server, queue_adapter]
  end

  MissionControl::Jobs.applications.add(app, queue_adapters_by_name)
end
