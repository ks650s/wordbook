class TagsController < ApplicationController

  def index
    @tags = Tag.all.order(:id)
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)
    if @tag.save
      redirect_to tags_path
    else
      render 'new', status: :unprocessable_entity
    end
  end

  def edit
    @tag = Tag.find(params[:id])
  end

  def update
    @tag = Tag.find(params[:id])
    if @tag.update(tag_params)
      redirect_to tags_path
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  def destroy
    Tag.find(params[:id]).destroy
    redirect_to tags_path
  end

  private
  def tag_params
    params.require(:tag).permit(:name)
  end
end
