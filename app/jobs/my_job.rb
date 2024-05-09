# frozen_string_literal: true

class MyJob < ApplicationJob
  def perform(*args)
    Rails.logger.debug args
  end
end
