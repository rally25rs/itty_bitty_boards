class API::ChildBoardsController < API::ApplicationController
  # protect_from_forgery with: :null_session
  respond_to :json
  skip_before_action :authenticate_token!, only: %i[show current]
  before_action :authenticate_child_token!, only: %i[show current]

  # GET /boards/1 or /boards/1.json
  def show
    set_child_board
    @board_with_images = @board.api_view_with_images(current_account.user)
    child_permissions = {
      can_edit: false,
      can_delete: false,
    }
    child_board_info = {
      child_board_id: @child_board.id,
    }
    render json: @board_with_images.merge(child_permissions).merge(child_board_info)
  end

  def current
    @boards = boards_for_child
    @boards_with_images = @boards.map do |board|
      board.api_view_with_images
    end
    render json: @boards_with_images
  end

  def destroy
    @child_board = ChildBoard.find(params[:id])
    @child_board.destroy
    render json: { message: "Board deleted" }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_child_board
    @child_board = ChildBoard.includes(board: { board_images: { image: [:docs, :audio_files_attachments, :audio_files_blobs] } }).find(params[:id])
    @board = @child_board.board
  end

  def boards_for_child
    current_account.child_boards.with_artifacts
  end

  def image_params
    params.require(:image).permit(:label, :image_prompt, :display_image, audio_files: [], docs: [:id, :child_id, :image, :documentable_id, :documentable_type, :processed, :_destroy])
  end

  # Only allow a list of trusted parameters through.
  def board_params
    params.require(:board).permit(:child_id,
                                  :name,
                                  :parent_id,
                                  :parent_type,
                                  :description,
                                  :predefined,
                                  :number_of_columns,
                                  :next_words,
                                  :images,
                                  :layout,
                                  :image_ids,
                                  :image_id,
                                  :query,
                                  :page,
                                  :display_image_url)
  end
end
