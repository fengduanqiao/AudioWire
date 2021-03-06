class FriendshipsController < ApplicationController
  before_filter :after_token_authentication
  respond_to :json

  def after_token_authentication
    if params[:token].present?
      @user = User.find_by_authentication_token(params[:token])
      if (@user == nil)
        render :status=>403, json: {:success=>false, :error=>'Token is invalid'}
      end
    else
      render :status=>403, json: {:success=>false, :error=>'token field is missing'}
    end
  end

  def index
    user = User.find_by_authentication_token(params[:token])
    list = []
    user.friendships.each do |friendship|
      res = {}
      res[:id] = friendship[:id]
      res[:friend_id] = friendship[:friend_id]
      res[:user_id] = friendship[:user_id]
      res[:created_at] = friendship[:created_at]
      res[:updated_at] = friendship[:updated_at]
      res[:first_name] = User.find(friendship[:friend_id])[:first_name]
      res[:last_name] = User.find(friendship[:friend_id])[:last_name]
      list.append(res)
    end
    render :status => 200, :json=>{:success=>true, :friends => list}
  end

  def create
    user = User.find_by_authentication_token(params[:token])
    friend = User.find_by_email(params[:friend_email])
    if !friend
      UserMailer.ask_join(user, params[:friend_email]).deliver
      render :status => 404, :json=>{:success=>false, :error=>"Friend does not exists"}
      return
    end
    @friendship = get_friendship(user.id, friend.id)
    if @friendship.nil?

      @friendship = user.friendships.build(:friend_id=>friend.id)
      if @friendship.save
        render :status => 201, :json=>{:success=>true, :friend=>@friendship}
      else
        render :status=>:unprocessable_entity, :json=>{:success=>false, :errors=>@friendship.errors}
      end
    else
      render :status=> 200, :json=>{:success=>true, :friend=>@friendship}
    end
  end

  def destroy
    user = User.find_by_authentication_token(params[:token])
    friend = User.find_by_email(params[:friend_email])
    @friendship = get_friendship(user.id, friend.id)
    if @friendship.nil?
      render :status => 404, :json=>{:success=>false, :error=>"User #{friend_id} is not your friend"}
      return
    end
    @friendship.destroy
    render :status => 200, :json=>{:success=>true, :message=>"Friendship no longer exists"}
  end

  protected
  def get_friendship(user_id, friend_id)
    Friendship.where("user_id = ? AND friend_id = ?", user_id, friend_id)[0]
  end
end
