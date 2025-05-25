# frozen_string_literal: true

class Pagination
  attr_reader :page, :per_page, :total_count, :total_pages, :offset

  def initialize(relation, params)
    @relation = relation
    @page = [params[:page].to_i, 1].max
    @per_page = [params[:per_page].to_i, 12].max
    @total_count = @relation.count
    @total_pages = (@total_count.to_f / @per_page).ceil
    @page = [@page, @total_pages].min if @total_pages > 0
    @offset = (@page - 1) * @per_page
  end

  def paginated_relation
    @relation.offset(offset).limit(per_page)
  end
end