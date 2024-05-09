# frozen_string_literal: true

class CategoriesController < ApplicationController
  def show
    @category = Category.find(params[:id])
    @products = @category.products
    if params[:max].present?
      @products = @products.where('price <= ?', params[:max])
    end
    return unless params[:min].present?

    @products = @products.where('price >= ?', params[:min])
  end
end
